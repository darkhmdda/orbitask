part of 'home_screen.dart';

extension _HomeScreenSync on _HomeScreenState {
  Duration get _cloudSyncPollInterval {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      return const Duration(seconds: 20);
    }
    return const Duration(seconds: 30);
  }

  /// Espera tras una edición antes de la subida rápida, para agrupar
  /// cambios seguidos (por ejemplo, completar varias tareas).
  Duration get _cloudSyncDebounceDelay => const Duration(milliseconds: 300);

  void _startRealtimeSubscription() {
    if (!widget.cloudSyncService.isConfigured ||
        widget.authService.currentUser == null) {
      return;
    }

    _cloudRealtimeChannel = widget.cloudSyncService.subscribeToRemoteChanges(
      _handleRemoteChange,
    );
  }

  /// Aplica al momento cada cambio que avisa Realtime. Los ecos de los
  /// cambios propios no modifican nada y se descartan solos, así que ya no
  /// se ignoran avisos durante unos segundos tras cada sincronización (lo
  /// que hacía perder los cambios de otros dispositivos en esa ventana).
  void _handleRemoteChange(RemoteChange change) {
    if (!mounted) return;

    // El tema va por su propio camino: se aplica al momento y no lanza una
    // sincronización de las tareas.
    if (change.table == RemoteChange.tablePreferences) {
      final themeId = widget.cloudSyncService.applyRemoteTheme(change);
      if (themeId != null) widget.onCloudThemeChanged(themeId);
      return;
    }

    _handleRemoteOutcome(
      change,
      widget.cloudSyncService.applyRemoteChange(change),
    );
  }

  void _handleRemoteOutcome(RemoteChange change, RemoteChangeOutcome outcome) {
    switch (outcome) {
      case RemoteChangeOutcome.unchanged:
        return;
      case RemoteChangeOutcome.applied:
        _scheduleRemoteReload();
      case RemoteChangeOutcome.needsAttachmentDownload:
        unawaited(_downloadRemoteAttachment(change));
      case RemoteChangeOutcome.needsFullSync:
        _scheduleCloudSync(immediate: true);
    }
  }

  /// Descarga solo el archivo del adjunto que avisó Realtime, sin
  /// sincronización completa. Si no puede, la pide.
  Future<void> _downloadRemoteAttachment(RemoteChange change) async {
    final outcome = await widget.cloudSyncService.applyRemoteAttachment(change);
    if (!mounted) return;
    // applyRemoteAttachment nunca vuelve a pedir la descarga, pero por si
    // acaso no se entra en bucle.
    _handleRemoteOutcome(
      change,
      outcome == RemoteChangeOutcome.needsAttachmentDownload
          ? RemoteChangeOutcome.needsFullSync
          : outcome,
    );
  }

  /// Agrupa los avisos que llegan seguidos (otro dispositivo que sube
  /// varias filas a la vez) en una sola recarga.
  void _scheduleRemoteReload() {
    _remoteReloadTimer?.cancel();
    _remoteReloadTimer = Timer(
      const Duration(milliseconds: 150),
      () => unawaited(_reloadAndUpdateReminders()),
    );
  }

  /// Recarga los datos y reprograma solo los recordatorios de las tareas
  /// que cambiaron (también cancela los de tareas borradas en otro sitio).
  Future<void> _reloadAndUpdateReminders() async {
    final oldTasks = _tasks;
    final oldReminders = _remindersByTask;

    await _loadData();
    if (!mounted) return;

    final plan = ReminderPlan.diff(
      oldTasks: oldTasks,
      oldReminders: oldReminders,
      newTasks: _tasks,
      newReminders: _remindersByTask,
    );
    if (plan.isEmpty) return;

    await widget.notificationService.cancelReminders(plan.toCancel);
    for (final item in plan.toSchedule) {
      await widget.notificationService.scheduleTaskReminders(
        task: item.task,
        reminders: item.reminders,
      );
    }
  }

  /// Programa una sincronización.
  ///
  /// - Sin `immediate` (tras una edición local): espera un momento para
  ///   agrupar cambios y hace una **subida rápida**, que sube solo lo
  ///   modificado sin descargar nada antes.
  /// - Con `immediate` (al abrir la app, sondeo, aviso de Realtime que no se
  ///   puede aplicar suelto, reintentos): **sincronización completa**.
  ///
  /// Si se piden las dos antes de que arranque, gana la completa.
  void _scheduleCloudSync({bool immediate = false}) {
    if (!widget.cloudSyncService.isConfigured ||
        widget.authService.currentUser == null) {
      return;
    }

    if (immediate) _fullSyncPending = true;

    _cloudSyncDebounce?.cancel();
    _cloudSyncDebounce = Timer(
      immediate ? Duration.zero : _cloudSyncDebounceDelay,
      () {
        final fullSync = _fullSyncPending;
        _fullSyncPending = false;
        unawaited(_runAutomaticCloudSync(fullSync: fullSync));
      },
    );
  }

  Future<void> _runAutomaticCloudSync({bool fullSync = true}) async {
    if (!widget.cloudSyncService.isConfigured ||
        widget.authService.currentUser == null) {
      return;
    }

    if (_cloudSyncing) {
      _cloudSyncQueued = true;
      if (fullSync) _queuedFullSync = true;
      return;
    }

    if (mounted) {
      _applyState(() => _cloudSyncing = true);
    }

    var needsFullSync = false;
    try {
      if (fullSync) {
        await widget.cloudSyncService.syncNow();
        if (!mounted) return;

        // El tema guardado ahora, no el que se leyó al empezar: si se cambió
        // mientras se sincronizaba, aplicar el de entonces lo revertiría.
        widget.onCloudThemeChanged(widget.cloudSyncService.localThemeId);
        _markCloudSyncSucceeded();
        await _reloadAndUpdateReminders();
      } else {
        final result = await widget.cloudSyncService.pushLocalChanges();
        if (!mounted) return;

        // No cambia nada en local, así que no hace falta recargar.
        needsFullSync = result.needsFullSync;
        if (!needsFullSync) _markCloudSyncSucceeded();
      }
    } catch (error) {
      if (mounted) {
        _applyState(() {
          _cloudSyncFailed = true;
          _cloudSyncError = error.toString();
        });
      }
      _scheduleCloudRetry();
    } finally {
      final queued = _cloudSyncQueued;
      final queuedFull = _queuedFullSync || needsFullSync;
      _cloudSyncQueued = false;
      _queuedFullSync = false;

      if (mounted) {
        _applyState(() => _cloudSyncing = false);
      }

      if (queued || needsFullSync) {
        _cloudSyncRetryTimer?.cancel();
        _cloudSyncRetryTimer = null;
        if (queuedFull) {
          _scheduleCloudSync(immediate: true);
        } else {
          _scheduleCloudSync();
        }
      }
    }
  }

  /// Sube el tema recién aplicado, sin esperar ni tocar las tareas.
  Future<void> _pushThemeToCloud() async {
    if (!widget.cloudSyncService.isConfigured ||
        widget.authService.currentUser == null) {
      return;
    }
    try {
      await widget.cloudSyncService.pushTheme();
    } catch (_) {
      // Sin conexión, por ejemplo: la sincronización completa lo subirá.
      _scheduleCloudSync(immediate: true);
    }
  }

  void _markCloudSyncSucceeded() {
    _cloudSyncFailureCount = 0;
    _cloudSyncRetryTimer?.cancel();
    _cloudSyncRetryTimer = null;

    _applyState(() {
      _cloudSyncFailed = false;
      _cloudSyncError = null;
      _lastCloudSyncAt = widget.cloudSyncService.lastSuccessfulSyncAt;
    });
  }

  void _scheduleCloudRetry() {
    _cloudSyncFailureCount += 1;
    _cloudSyncRetryTimer?.cancel();

    const delays = <Duration>[
      Duration(seconds: 5),
      Duration(seconds: 15),
      Duration(seconds: 30),
      Duration(minutes: 1),
    ];

    final index = _cloudSyncFailureCount - 1;
    final delay = delays[index < delays.length ? index : delays.length - 1];

    _cloudSyncRetryTimer = Timer(
      delay,
      () => _scheduleCloudSync(immediate: true),
    );
  }

  String _formatSyncTime(DateTime? value) {
    if (value == null) return 'Todavía no se ha sincronizado';

    final now = DateTime.now();
    final difference = now.difference(value);

    if (difference.inSeconds < 60) return 'Hace unos segundos';
    if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    }
    if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} h';
    }

    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/${value.year} $hour:$minute';
  }

  Future<void> _showSyncStatus() async {
    final connected = widget.authService.currentUser != null;
    final theme = Theme.of(context);

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Estado de sincronización'),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  _cloudSyncFailed
                      ? Icons.cloud_off_outlined
                      : (_cloudSyncing
                          ? Icons.sync_rounded
                          : (connected
                              ? Icons.cloud_done_outlined
                              : Icons.storage_rounded)),
                ),
                title: Text(
                  _cloudSyncing
                      ? 'Sincronizando…'
                      : (_cloudSyncFailed
                          ? 'Hay cambios pendientes de sincronizar'
                          : (connected
                              ? 'Sincronización activa'
                              : 'Solo almacenamiento local')),
                ),
                subtitle: Text(
                  connected
                      ? 'Última sincronización: ${_formatSyncTime(_lastCloudSyncAt)}'
                      : 'Inicia sesión para sincronizar este dispositivo con la nube.',
                ),
              ),
              if (_cloudSyncFailed && _cloudSyncError != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _cloudSyncError!,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
              if (connected) ...[
                const SizedBox(height: 8),
                Text(
                  'Orbitask reintenta automáticamente cuando vuelves a abrir la app, recuperas conexión o llega un cambio por Realtime.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          if (connected)
            FilledButton.icon(
              onPressed: _cloudSyncing
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      _scheduleCloudSync(immediate: true);
                    },
              icon: const Icon(Icons.sync_rounded),
              label: const Text('Sincronizar ahora'),
            ),
        ],
      ),
    );
  }

}
