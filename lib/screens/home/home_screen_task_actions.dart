part of 'home_screen.dart';

extension _HomeScreenTaskActions on _HomeScreenState {
  Future<void> _quickAdd() async {
    final title = _quickAddController.text.trim();
    if (title.isEmpty) return;

    final now = DateTime.now();
    final task = Task(
      id: now.microsecondsSinceEpoch.toString(),
      title: title,
      listId: _selectedListId ?? 'inbox',
      createdAt: now,
      updatedAt: now,
    );

    try {
      await widget.repository.createTask(task, const [], const []);
      if (!mounted) return;

      _applyState(() {
        _tasks = [..._tasks, task];
        _quickAddController.clear();
        if (_selectedListId == null) {
          _filterIndex = 0;
        }
      });

      _showMessage('Tarea guardada localmente.');
      unawaited(_updateAndroidHomeWidgets(_tasks));
      _scheduleCloudSync();
    } catch (error) {
      if (!mounted) return;
      _showDatabaseError(error);
    }
  }

  Future<void> _openTaskForm({Task? task}) async {
    final now = DateTime.now();
    final taskId = task?.id ?? now.microsecondsSinceEpoch.toString();
    final existingSubtasks =
        task == null ? const <Subtask>[] : (_subtasksByTask[task.id] ?? const []);
    final existingReminders =
        task == null ? const <Reminder>[] : (_remindersByTask[task.id] ?? const []);

    final result = await showDialog<TaskFormResult>(
      context: context,
      builder: (context) => TaskFormDialog(
        taskId: taskId,
        task: task,
        lists: _lists,
        subtasks: existingSubtasks,
        reminders: existingReminders,
        initialListId: _selectedListId ?? 'inbox',
      ),
    );

    if (result == null || !mounted) return;

    try {
      if (task == null) {
        final newTask = Task(
          id: taskId,
          title: result.title,
          description: result.description,
          priority: result.priority,
          dueDate: result.dueDate,
          listId: result.listId,
          createdAt: now,
          updatedAt: now,
        );

        await widget.repository.createTask(
          newTask,
          result.subtasks,
          result.reminders,
        );

        String? reminderWarning;
        if (result.reminders.any((item) => item.enabled)) {
          await widget.notificationService.requestPermissions(
            exactAlarms: true,
          );
          reminderWarning = await widget.notificationService
              .scheduleTaskReminders(
                task: newTask,
                reminders: result.reminders,
              );
        }

        if (!mounted) return;

        _applyState(() {
          _tasks = [..._tasks, newTask];
          _subtasksByTask = {
            ..._subtasksByTask,
            newTask.id: result.subtasks,
          };
          _remindersByTask = {
            ..._remindersByTask,
            newTask.id: result.reminders,
          };
          if (_selectedListId == null) {
            _filterIndex = 0;
          }
        });

        _showMessage(
          reminderWarning ?? 'Tarea creada y guardada.',
        );
        unawaited(_updateAndroidHomeWidgets(_tasks));
        _scheduleCloudSync();
      } else {
        final updatedTask = task.copyWith(
          title: result.title,
          description: result.description,
          priority: result.priority,
          dueDate: result.dueDate,
          clearDueDate: result.dueDate == null,
          listId: result.listId,
          updatedAt: DateTime.now(),
        );

        await widget.repository.updateTask(
          updatedTask,
          result.subtasks,
          result.reminders,
        );

        await widget.notificationService.cancelReminders(existingReminders);
        String? reminderWarning;
        if (!updatedTask.completed &&
            result.reminders.any((item) => item.enabled)) {
          await widget.notificationService.requestPermissions(
            exactAlarms: true,
          );
          reminderWarning = await widget.notificationService
              .scheduleTaskReminders(
                task: updatedTask,
                reminders: result.reminders,
              );
        }

        if (!mounted) return;

        _applyState(() {
          _tasks = _tasks
              .map((item) => item.id == updatedTask.id ? updatedTask : item)
              .toList(growable: false);
          _subtasksByTask = {
            ..._subtasksByTask,
            updatedTask.id: result.subtasks,
          };
          _remindersByTask = {
            ..._remindersByTask,
            updatedTask.id: result.reminders,
          };
        });

        _showMessage(
          reminderWarning ?? 'Tarea actualizada y guardada.',
        );
        unawaited(_updateAndroidHomeWidgets(_tasks));
        _scheduleCloudSync();
      }
    } catch (error) {
      if (!mounted) return;
      _showDatabaseError(error);
    }
  }

  Future<void> _toggleCompleted(Task task, bool completed) async {
    final updatedTask = task.copyWith(
      completed: completed,
      updatedAt: DateTime.now(),
    );

    try {
      await widget.repository.updateTaskOnly(updatedTask);

      final reminders = _remindersByTask[task.id] ?? const <Reminder>[];
      String? reminderWarning;
      if (completed) {
        await widget.notificationService.cancelReminders(reminders);
      } else {
        reminderWarning = await widget.notificationService
            .scheduleTaskReminders(
              task: updatedTask,
              reminders: reminders,
            );
      }

      if (!mounted) return;

      _applyState(() {
        _tasks = _tasks
            .map((item) => item.id == updatedTask.id ? updatedTask : item)
            .toList(growable: false);
      });

      if (reminderWarning != null) {
        _showMessage(reminderWarning);
      }
      unawaited(_updateAndroidHomeWidgets(_tasks));
      _scheduleCloudSync();
    } catch (error) {
      if (!mounted) return;
      _showDatabaseError(error);
    }
  }

  Future<void> _toggleSubtask(Subtask subtask, bool completed) async {
    final updated = subtask.copyWith(
      completed: completed,
      updatedAt: DateTime.now(),
    );

    try {
      await widget.repository.updateSubtaskCompleted(updated);
      if (!mounted) return;

      final current = _subtasksByTask[subtask.taskId] ?? const <Subtask>[];
      final updatedList = current
          .map((item) => item.id == updated.id ? updated : item)
          .toList(growable: false);

      _applyState(() {
        _subtasksByTask = {
          ..._subtasksByTask,
          subtask.taskId: updatedList,
        };
      });
      _scheduleCloudSync();
    } catch (error) {
      if (!mounted) return;
      _showDatabaseError(error);
    }
  }

  Future<void> _deleteTask(Task task) async {
    final reminders = _remindersByTask[task.id] ?? const <Reminder>[];

    try {
      await widget.repository.trashTask(task.id);
      await widget.notificationService.cancelReminders(reminders);
      if (!mounted) return;

      final trashedAt = DateTime.now();
      _applyState(() {
        _tasks = _tasks
            .map(
              (item) => item.id == task.id
                  ? item.copyWith(
                      trashedAt: trashedAt,
                      updatedAt: trashedAt,
                    )
                  : item,
            )
            .toList(growable: false);
      });

      ScaffoldMessenger.of(context).clearSnackBars();
      unawaited(_updateAndroidHomeWidgets(_tasks));
      _scheduleCloudSync();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('“${task.title}” se movió a la papelera.'),
          action: SnackBarAction(
            label: 'Deshacer',
            onPressed: () => _restoreTaskFromTrash(task),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _showDatabaseError(error);
    }
  }

  Future<void> _restoreTaskFromTrash(Task task) async {
    try {
      await widget.repository.restoreTask(task.id);
      if (!mounted) return;

      final restoredAt = DateTime.now();
      final restoredTask = task.copyWith(
        clearTrashedAt: true,
        updatedAt: restoredAt,
      );

      _applyState(() {
        _tasks = _tasks
            .map((item) => item.id == task.id ? restoredTask : item)
            .toList(growable: false);
      });

      final reminders = _remindersByTask[task.id] ?? const <Reminder>[];
      String? reminderWarning;
      if (!restoredTask.completed) {
        reminderWarning =
            await widget.notificationService.scheduleTaskReminders(
          task: restoredTask,
          reminders: reminders,
        );
      }

      if (!mounted) return;
      if (reminderWarning != null) {
        _showMessage(reminderWarning);
      } else {
        _showMessage('Tarea restaurada.');
      }
      unawaited(_updateAndroidHomeWidgets(_tasks));
      _scheduleCloudSync();
    } catch (error) {
      if (!mounted) return;
      _showDatabaseError(error);
    }
  }

  Future<void> _deleteTaskPermanently(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar definitivamente'),
        content: Text(
          '“${task.title}” se eliminará de forma permanente. '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final reminders = _remindersByTask[task.id] ?? const <Reminder>[];
      await widget.repository.deleteTask(task.id);
      await widget.notificationService.cancelReminders(reminders);
      if (!mounted) return;

      _applyState(() {
        _tasks = _tasks.where((item) => item.id != task.id).toList();
        _subtasksByTask = Map<String, List<Subtask>>.from(_subtasksByTask)
          ..remove(task.id);
        _remindersByTask =
            Map<String, List<Reminder>>.from(_remindersByTask)
              ..remove(task.id);
      });

      _showMessage('Tarea eliminada definitivamente.');
      unawaited(_updateAndroidHomeWidgets(_tasks));
      _scheduleCloudSync();
    } catch (error) {
      if (!mounted) return;
      _showDatabaseError(error);
    }
  }

  Future<void> _emptyTrash() async {
    final trashedTasks =
        _tasks.where((task) => task.trashedAt != null).toList(growable: false);
    if (trashedTasks.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vaciar papelera'),
        content: Text(
          'Se eliminarán definitivamente ${trashedTasks.length} '
          '${trashedTasks.length == 1 ? 'tarea' : 'tareas'}. '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Vaciar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      for (final task in trashedTasks) {
        final reminders = _remindersByTask[task.id] ?? const <Reminder>[];
        await widget.repository.deleteTask(task.id);
        await widget.notificationService.cancelReminders(reminders);
      }

      if (!mounted) return;
      final trashedIds = trashedTasks.map((task) => task.id).toSet();
      final newSubtasks =
          Map<String, List<Subtask>>.from(_subtasksByTask)
            ..removeWhere((id, _) => trashedIds.contains(id));
      final newReminders =
          Map<String, List<Reminder>>.from(_remindersByTask)
            ..removeWhere((id, _) => trashedIds.contains(id));

      _applyState(() {
        _tasks =
            _tasks.where((task) => !trashedIds.contains(task.id)).toList();
        _subtasksByTask = newSubtasks;
        _remindersByTask = newReminders;
      });

      _showMessage('Papelera vaciada.');
      unawaited(_updateAndroidHomeWidgets(_tasks));
      _scheduleCloudSync();
    } catch (error) {
      if (!mounted) return;
      _showDatabaseError(error);
    }
  }

  Future<void> _reconcileNotifications(
    List<Task> tasks,
    Map<String, List<Reminder>> remindersByTask,
  ) async {
    for (final task in tasks) {
      final reminders = remindersByTask[task.id] ?? const <Reminder>[];
      if (task.trashedAt != null || task.completed) {
        await widget.notificationService.cancelReminders(reminders);
        continue;
      }

      await widget.notificationService.scheduleTaskReminders(
        task: task,
        reminders: reminders,
      );
    }
  }

}
