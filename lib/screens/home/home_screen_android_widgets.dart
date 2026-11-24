part of 'home_screen.dart';

/// Canal compartido con los widgets de Android (ver `MainActivity.kt`).
const MethodChannel _androidWidgetChannel = MethodChannel(
  'com.darkhmdda.orbitask/widgets',
);

extension _HomeScreenAndroidWidgets on _HomeScreenState {
  bool get _supportsAndroidWidgets =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Escucha los avisos del lado nativo (una tarea marcada en un widget
  /// mientras la app sigue en marcha en segundo plano).
  void _listenToAndroidWidgets() {
    if (!_supportsAndroidWidgets) return;
    _androidWidgetChannel.setMethodCallHandler((call) async {
      if (call.method == 'widgetTasksChanged') {
        await _consumeAndroidWidgetEvents();
      }
      return null;
    });
  }

  void _stopListeningToAndroidWidgets() {
    if (!_supportsAndroidWidgets) return;
    _androidWidgetChannel.setMethodCallHandler(null);
  }

  /// Manda a los widgets las tareas y los colores del tema activo.
  ///
  /// Los widgets no leen la base de datos: el SQLite de Android y el de la
  /// app (paquete `sqlite3`) no pueden abrir el mismo archivo en el mismo
  /// proceso sin riesgo de corromperlo.
  Future<void> _updateAndroidHomeWidgets(List<Task> tasks) async {
    if (!_supportsAndroidWidgets) return;

    final preset = AppTheme.presetFor(widget.themeId);
    final widgetTasks = [
      for (final task in tasks)
        if (task.trashedAt == null)
          {
            'id': task.id,
            'title': task.title,
            'priority': task.priority.index,
            'dueMillis': task.dueDate?.millisecondsSinceEpoch,
            'completed': task.completed,
            'updatedAt': task.updatedAt.millisecondsSinceEpoch,
            'reminderIds': [
              for (final reminder
                  in _remindersByTask[task.id] ?? const <Reminder>[])
                reminder.id,
            ],
          },
    ];

    try {
      await _androidWidgetChannel.invokeMethod<void>('updateWidgets', {
        'tasksJson': jsonEncode(widgetTasks),
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

  /// Recoge lo que pasó en los widgets: tareas marcadas o desmarcadas (se
  /// guardan como si se hubieran marcado en la app, con sus recordatorios y
  /// su sincronización) y la acción pendiente (abrir una tarea o crear una).
  ///
  /// Se llama al terminar cada carga de datos y cuando el lado nativo avisa.
  Future<void> _consumeAndroidWidgetEvents() async {
    if (!_supportsAndroidWidgets ||
        _handlingAndroidWidgetEvents ||
        _loading ||
        !mounted) {
      return;
    }
    _handlingAndroidWidgetEvents = true;

    try {
      final toggles = await _androidWidgetChannel
              .invokeListMethod<Map<Object?, Object?>>('takeWidgetToggles') ??
          const <Map<Object?, Object?>>[];
      for (final toggle in toggles) {
        final task = _activeTaskById(toggle['taskId'] as String?);
        final completed = toggle['completed'] as bool?;
        if (task == null || completed == null || task.completed == completed) {
          continue;
        }
        await _toggleCompleted(task, completed);
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
