import 'package:flutter_test/flutter_test.dart';
import 'package:orbitask/models/reminder.dart';
import 'package:orbitask/models/subtask.dart';
import 'package:orbitask/models/task.dart';
import 'package:orbitask/models/task_list.dart';

void main() {
  final createdAt = DateTime.utc(2026, 10, 1, 12);
  final updatedAt = DateTime.utc(2026, 10, 2, 12);

  group('Task', () {
    test('copyWith conserva los valores no modificados', () {
      final task = Task(
        id: 'task-1',
        title: 'Original',
        description: 'Descripcion',
        priority: TaskPriority.medium,
        dueDate: DateTime.utc(2026, 10, 10),
        completed: false,
        listId: 'personal',
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      final copy = task.copyWith(title: 'Cambiada');

      expect(copy.id, task.id);
      expect(copy.title, 'Cambiada');
      expect(copy.description, task.description);
      expect(copy.priority, task.priority);
      expect(copy.dueDate, task.dueDate);
      expect(copy.listId, task.listId);
      expect(copy.createdAt, task.createdAt);
    });

    test('clearDueDate elimina la fecha limite', () {
      final task = Task(
        id: 'task-1',
        title: 'Tarea',
        dueDate: DateTime.utc(2026, 10, 10),
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      final copy = task.copyWith(clearDueDate: true);

      expect(copy.dueDate, isNull);
    });

    test('clearTrashedAt restaura una tarea de la papelera', () {
      final task = Task(
        id: 'task-1',
        title: 'Tarea',
        trashedAt: DateTime.utc(2026, 10, 4),
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      final restored = task.copyWith(clearTrashedAt: true);

      expect(restored.trashedAt, isNull);
    });
  });

  group('Reminder', () {
    test('isCustom es true cuando no hay offset', () {
      final reminder = Reminder(
        id: 'reminder-1',
        taskId: 'task-1',
        scheduledAt: DateTime.utc(2026, 10, 10, 8),
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      expect(reminder.isCustom, isTrue);
    });

    test('isCustom es false cuando existe offset', () {
      final reminder = Reminder(
        id: 'reminder-1',
        taskId: 'task-1',
        scheduledAt: DateTime.utc(2026, 10, 10, 8),
        offsetMinutes: 30,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      expect(reminder.isCustom, isFalse);
    });

    test('clearOffsetMinutes convierte el recordatorio en personalizado', () {
      final reminder = Reminder(
        id: 'reminder-1',
        taskId: 'task-1',
        scheduledAt: DateTime.utc(2026, 10, 10, 8),
        offsetMinutes: 60,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      final copy = reminder.copyWith(clearOffsetMinutes: true);

      expect(copy.offsetMinutes, isNull);
      expect(copy.isCustom, isTrue);
    });
  });

  group('Subtask', () {
    test('copyWith actualiza estado y posicion', () {
      final subtask = Subtask(
        id: 'sub-1',
        taskId: 'task-1',
        title: 'Subtarea',
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      final copy = subtask.copyWith(
        completed: true,
        position: 3,
      );

      expect(copy.completed, isTrue);
      expect(copy.position, 3);
      expect(copy.taskId, 'task-1');
    });
  });

  group('TaskList', () {
    test('copyWith conserva id y permite cambiar nombre', () {
      final list = TaskList(
        id: 'personal',
        name: 'Personal',
        icon: 'home',
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      final copy = list.copyWith(name: 'Casa');

      expect(copy.id, 'personal');
      expect(copy.name, 'Casa');
      expect(copy.icon, 'home');
    });
  });
}
