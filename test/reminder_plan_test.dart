import 'package:flutter_test/flutter_test.dart';
import 'package:orbitask/models/reminder.dart';
import 'package:orbitask/models/task.dart';
import 'package:orbitask/services/reminder_plan.dart';

DateTime _at(int minute) => DateTime.utc(2026, 11, 24, 12, minute);

Task _task(String id, {int updated = 1, bool completed = false, DateTime? trashedAt}) {
  return Task(
    id: id,
    title: id,
    completed: completed,
    trashedAt: trashedAt,
    createdAt: _at(0),
    updatedAt: _at(updated),
  );
}

Reminder _reminder(String id, String taskId, {int updated = 1}) {
  return Reminder(
    id: id,
    taskId: taskId,
    scheduledAt: DateTime.utc(2026, 12, 1, 9),
    createdAt: _at(0),
    updatedAt: _at(updated),
  );
}

void main() {
  test('si nada cambia, no toca ningún recordatorio', () {
    final tasks = [_task('t1'), _task('t2')];
    final reminders = {
      't1': [_reminder('r1', 't1')],
    };

    final plan = ReminderPlan.diff(
      oldTasks: tasks,
      oldReminders: reminders,
      newTasks: tasks,
      newReminders: reminders,
    );

    expect(plan.isEmpty, isTrue);
  });

  test('solo reprograma la tarea que cambió', () {
    final plan = ReminderPlan.diff(
      oldTasks: [_task('t1'), _task('t2')],
      oldReminders: {
        't1': [_reminder('r1', 't1')],
        't2': [_reminder('r2', 't2')],
      },
      newTasks: [_task('t1', updated: 5), _task('t2')],
      newReminders: {
        't1': [_reminder('r1', 't1')],
        't2': [_reminder('r2', 't2')],
      },
    );

    expect(plan.toCancel.map((r) => r.id), ['r1']);
    expect(plan.toSchedule.map((item) => item.task.id), ['t1']);
  });

  test('una tarea completada en otro dispositivo cancela sus avisos', () {
    final plan = ReminderPlan.diff(
      oldTasks: [_task('t1')],
      oldReminders: {
        't1': [_reminder('r1', 't1')],
      },
      newTasks: [_task('t1', updated: 2, completed: true)],
      newReminders: {
        't1': [_reminder('r1', 't1')],
      },
    );

    expect(plan.toCancel.map((r) => r.id), ['r1']);
    expect(plan.toSchedule, isEmpty);
  });

  test('una tarea en la Papelera cancela sus avisos', () {
    final plan = ReminderPlan.diff(
      oldTasks: [_task('t1')],
      oldReminders: {
        't1': [_reminder('r1', 't1')],
      },
      newTasks: [_task('t1', updated: 2, trashedAt: _at(2))],
      newReminders: {
        't1': [_reminder('r1', 't1')],
      },
    );

    expect(plan.toCancel.map((r) => r.id), ['r1']);
    expect(plan.toSchedule, isEmpty);
  });

  test('una tarea borrada en otro dispositivo cancela sus avisos', () {
    // Antes esto no se hacía: la reconciliación solo recorría las tareas que
    // seguían existiendo, y el aviso de una tarea borrada seguía programado.
    final plan = ReminderPlan.diff(
      oldTasks: [_task('t1')],
      oldReminders: {
        't1': [_reminder('r1', 't1')],
      },
      newTasks: const [],
      newReminders: const {},
    );

    expect(plan.toCancel.map((r) => r.id), ['r1']);
    expect(plan.toSchedule, isEmpty);
  });

  test('un recordatorio nuevo o modificado se programa', () {
    final plan = ReminderPlan.diff(
      oldTasks: [_task('t1')],
      oldReminders: {
        't1': [_reminder('r1', 't1')],
      },
      newTasks: [_task('t1')],
      newReminders: {
        't1': [_reminder('r1', 't1', updated: 3), _reminder('r2', 't1')],
      },
    );

    expect(plan.toCancel.map((r) => r.id), ['r1']);
    expect(plan.toSchedule.single.reminders.map((r) => r.id), ['r1', 'r2']);
  });

  test('desmarcar una tarea vuelve a programar sus avisos', () {
    final plan = ReminderPlan.diff(
      oldTasks: [_task('t1', completed: true)],
      oldReminders: {
        't1': [_reminder('r1', 't1')],
      },
      newTasks: [_task('t1', updated: 2)],
      newReminders: {
        't1': [_reminder('r1', 't1')],
      },
    );

    expect(plan.toSchedule.single.task.id, 't1');
  });
}
