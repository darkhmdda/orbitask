import '../models/reminder.dart';
import '../models/task.dart';

/// Qué recordatorios hay que cancelar y cuáles programar tras recargar datos.
///
/// Compara el estado anterior con el nuevo y solo toca las tareas que
/// cambiaron (la tarea o sus recordatorios). Así una sincronización no
/// reprograma todos los avisos, y los de tareas borradas en otro dispositivo
/// sí se cancelan.
class ReminderPlan {
  const ReminderPlan({
    required this.toCancel,
    required this.toSchedule,
  });

  /// Recordatorios antiguos de las tareas que cambiaron.
  final List<Reminder> toCancel;

  /// Tareas activas que cambiaron, con sus recordatorios nuevos.
  final List<ScheduledTaskReminders> toSchedule;

  bool get isEmpty => toCancel.isEmpty && toSchedule.isEmpty;

  static ReminderPlan diff({
    required List<Task> oldTasks,
    required Map<String, List<Reminder>> oldReminders,
    required List<Task> newTasks,
    required Map<String, List<Reminder>> newReminders,
  }) {
    final oldById = {for (final task in oldTasks) task.id: task};
    final newById = {for (final task in newTasks) task.id: task};
    final taskIds = <String>{
      ...oldById.keys,
      ...newById.keys,
      ...oldReminders.keys,
      ...newReminders.keys,
    };

    final toCancel = <Reminder>[];
    final toSchedule = <ScheduledTaskReminders>[];

    for (final taskId in taskIds) {
      final before = oldById[taskId];
      final after = newById[taskId];
      final remindersBefore = oldReminders[taskId] ?? const <Reminder>[];
      final remindersAfter = newReminders[taskId] ?? const <Reminder>[];

      final taskChanged = before?.updatedAt != after?.updatedAt ||
          before?.completed != after?.completed ||
          before?.trashedAt != after?.trashedAt;
      final remindersChanged = !_sameReminders(remindersBefore, remindersAfter);
      if (!taskChanged && !remindersChanged) continue;

      toCancel.addAll(remindersBefore);

      final active =
          after != null && !after.completed && after.trashedAt == null;
      if (active && remindersAfter.isNotEmpty) {
        toSchedule.add(
          ScheduledTaskReminders(task: after, reminders: remindersAfter),
        );
      }
    }

    return ReminderPlan(toCancel: toCancel, toSchedule: toSchedule);
  }

  static bool _sameReminders(List<Reminder> a, List<Reminder> b) {
    if (a.length != b.length) return false;
    final updatedById = {for (final reminder in a) reminder.id: reminder.updatedAt};
    for (final reminder in b) {
      if (updatedById[reminder.id] != reminder.updatedAt) return false;
    }
    return true;
  }
}

class ScheduledTaskReminders {
  const ScheduledTaskReminders({required this.task, required this.reminders});

  final Task task;
  final List<Reminder> reminders;
}
