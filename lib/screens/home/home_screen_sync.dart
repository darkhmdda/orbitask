part of 'home_screen.dart';

extension _HomeScreenSync on _HomeScreenState {
  Duration get _cloudSyncPollInterval {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      return const Duration(seconds: 20);
    }
    return const Duration(seconds: 30);
  }

  Duration get _cloudSyncDebounceDelay {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      return const Duration(milliseconds: 500);
    }
    return const Duration(milliseconds: 750);
  }

  void _startRealtimeSubscription() {
    if (!widget.cloudSyncService.isConfigured ||
        widget.authService.currentUser == null) {
      return;
    }

    _cloudRealtimeChannel = widget.cloudSyncService.subscribeToRemoteChanges(
      () {
        final ignoreUntil = _ignoreRealtimeUntil;
        if (ignoreUntil != null && DateTime.now().isBefore(ignoreUntil)) {
          return;
        }
        _scheduleCloudSync(immediate: true);
      },
    );
  }

  void _scheduleCloudSync({bool immediate = false}) {
    if (!widget.cloudSyncService.isConfigured ||
        widget.authService.currentUser == null) {
      return;
    }

    _cloudSyncDebounce?.cancel();
    _cloudSyncDebounce = Timer(
      immediate ? Duration.zero : _cloudSyncDebounceDelay,
      () => unawaited(_runAutomaticCloudSync()),
    );
  }

  Future<void> _runAutomaticCloudSync() async {
    if (!widget.cloudSyncService.isConfigured ||
        widget.authService.currentUser == null) {
      return;
    }

    if (_cloudSyncing) {
      _cloudSyncQueued = true;
      return;
    }

    if (mounted) {
      setState(() => _cloudSyncing = true);
    }

    _ignoreRealtimeUntil = DateTime.now().add(
      const Duration(seconds: 5),
    );

    try {
      final result = await widget.cloudSyncService.syncNow();
      if (!mounted) return;

      widget.onCloudThemeChanged(result.themeId);

      _cloudSyncFailureCount = 0;
      _cloudSyncRetryTimer?.cancel();
      _cloudSyncRetryTimer = null;

      setState(() {
        _cloudSyncFailed = false;
        _cloudSyncError = null;
        _lastCloudSyncAt = widget.cloudSyncService.lastSuccessfulSyncAt;
      });

      _notificationsReconciled = false;
      await _loadData();
    } catch (error) {
      if (mounted) {
        setState(() {
          _cloudSyncFailed = true;
          _cloudSyncError = error.toString();
        });
      }
      _scheduleCloudRetry();
    } finally {
      final shouldRetry = _cloudSyncQueued;
      _cloudSyncQueued = false;

      if (mounted) {
        setState(() => _cloudSyncing = false);
      }

      if (shouldRetry) {
        _cloudSyncRetryTimer?.cancel();
        _cloudSyncRetryTimer = null;
        _scheduleCloudSync(immediate: true);
      }
    }
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
