part of 'home_screen.dart';

/// Canal compartido con los widgets de Android (ver `MainActivity.kt`).
const MethodChannel _androidWidgetChannel = MethodChannel(
  'com.darkhmdda.orbitask/widgets',
);

extension _HomeScreenAndroidWidgets on _HomeScreenState {
  bool get _supportsAndroidWidgets =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Manda los colores del tema activo a los widgets y les pide repintarse.
  Future<void> _updateAndroidHomeWidgets(List<Task> tasks) async {
    if (!_supportsAndroidWidgets) return;

    final preset = AppTheme.presetFor(widget.themeId);

    try {
      await _androidWidgetChannel.invokeMethod<void>('updateWidgets', {
        'themeSurface': preset.surface.toARGB32(),
        'themeSurface2': preset.surface2.toARGB32(),
        'themeText': preset.text.toARGB32(),
        'themeMuted': preset.muted.toARGB32(),
        'themeAccent': preset.accent.toARGB32(),
        'themeAccent2': preset.accent2.toARGB32(),
        'themeBorder': preset.border.toARGB32(),
        'themeOnAccent': preset.chipSelectedText.toARGB32(),
        'themeLight': preset.light,
      });
    } catch (_) {
      // Los widgets de pantalla de inicio son un extra exclusivo de Android.
    }
  }

  /// Recoge lo que pasó en los widgets mientras la app estaba cerrada o en
  /// segundo plano: tareas marcadas o desmarcadas (para ajustar sus
  /// recordatorios) y la acción pendiente (abrir una tarea o crear una).
  ///
  /// Se llama al terminar cada carga de datos, así que los datos ya están al día.
  Future<void> _consumeAndroidWidgetEvents() async {
    if (!_supportsAndroidWidgets || _handlingAndroidWidgetEvents || !mounted) {
      return;
    }
    _handlingAndroidWidgetEvents = true;

    try {
      final changedIds = await _androidWidgetChannel
              .invokeListMethod<String>('takeChangedTasks') ??
          const <String>[];
      if (changedIds.isNotEmpty) {
        await _syncRemindersForWidgetChanges(changedIds);
        _scheduleCloudSync();
      }

      final action = await _androidWidgetChannel
          .invokeMapMethod<String, Object?>('takePendingAction');
      if (action == null || !mounted) return;

      switch (action['action']) {
        case 'openTask':
          final task = _activeTaskById(action['taskId'] as String?);
          if (task == null) {
            _showMessage('Esa tarea ya no existe.');
            return;
          }
          await _openTaskForm(task: task);
        case 'newTask':
          await _openTaskForm(
            initialDueDate: _widgetDueDate(action['dueDate'] as String?),
          );
      }
    } on MissingPluginException {
      // El canal no existe fuera de Android.
    } on PlatformException {
      // Si el lado nativo falla, la app sigue funcionando sin la acción.
    } finally {
      _handlingAndroidWidgetEvents = false;
    }
  }

  Future<void> _syncRemindersForWidgetChanges(List<String> taskIds) async {
    for (final taskId in taskIds) {
      final task = _taskById(taskId);
      if (task == null) continue;

      final reminders = _remindersByTask[taskId] ?? const <Reminder>[];
      if (reminders.isEmpty) continue;

      if (task.completed || task.trashedAt != null) {
        await widget.notificationService.cancelReminders(reminders);
      } else {
        await widget.notificationService.scheduleTaskReminders(
          task: task,
          reminders: reminders,
        );
      }
    }
  }

  Task? _taskById(String? taskId) {
    if (taskId == null) return null;
    for (final task in _tasks) {
      if (task.id == taskId) return task;
    }
    return null;
  }

  Task? _activeTaskById(String? taskId) {
    final task = _taskById(taskId);
    if (task == null || task.trashedAt != null) return null;
    return task;
  }

  /// El widget de calendario manda el día elegido como `yyyy-MM-dd`.
  /// Se usa la misma hora por defecto que el formulario (18:00).
  DateTime? _widgetDueDate(String? isoDate) {
    if (isoDate == null) return null;
    final date = DateTime.tryParse(isoDate);
    if (date == null) return null;
    return DateTime(date.year, date.month, date.day, 18);
  }
}
