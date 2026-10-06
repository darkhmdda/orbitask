import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbitask/database/local_database_native.dart';
import 'package:orbitask/models/reminder.dart';
import 'package:orbitask/models/subtask.dart';
import 'package:orbitask/models/task.dart';
import 'package:orbitask/models/task_attachment.dart';
import 'package:orbitask/models/task_list.dart';
import 'package:orbitask/repositories/todo_repository_native.dart';

void main() {
  late LocalDatabase database;
  late TodoRepository repository;

  final createdAt = DateTime.utc(2026, 10, 1, 12);
  final updatedAt = DateTime.utc(2026, 10, 2, 12);

  setUp(() {
    database = LocalDatabase.openInMemoryForTesting();
    repository = TodoRepository(database);
  });

  tearDown(() {
    database.close();
  });

  test('inicializa las listas base', () async {
    final lists = await repository.getAllLists();

    expect(lists.length, 5);
    expect(lists.first.id, 'inbox');
    expect(lists.first.isSystem, isTrue);
  });

  test('crea y recupera tarea con subtarea y recordatorio', () async {
    final task = Task(
      id: 'task-1',
      title: 'Estudiar',
      description: 'Repasar Orbitask',
      priority: TaskPriority.high,
      dueDate: DateTime.utc(2026, 10, 10, 20),
      listId: 'university',
      createdAt: createdAt,
      updatedAt: updatedAt,
    );

    final subtask = Subtask(
      id: 'sub-1',
      taskId: task.id,
      title: 'Repasar apuntes',
      createdAt: createdAt,
      updatedAt: updatedAt,
    );

    final reminder = Reminder(
      id: 'rem-1',
      taskId: task.id,
      scheduledAt: DateTime.utc(2026, 10, 10, 19, 30),
      offsetMinutes: 30,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );

    await repository.createTask(task, [subtask], [reminder]);

    final tasks = await repository.getAllTasks();
    final subtasks = await repository.getAllSubtasks();
    final reminders = await repository.getAllReminders();

    expect(tasks.single.id, 'task-1');
    expect(tasks.single.priority, TaskPriority.high);
    expect(tasks.single.listId, 'university');

    expect(subtasks.single.id, 'sub-1');
    expect(subtasks.single.taskId, 'task-1');

    expect(reminders.single.id, 'rem-1');
    expect(reminders.single.offsetMinutes, 30);
  });

  test('guarda y elimina adjuntos de una tarea', () async {
    final task = Task(
      id: 'task-attachment',
      title: 'Con archivo',
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
    await repository.createTask(task, const [], const []);

    final attachment = TaskAttachment(
      id: 'att-1',
      taskId: task.id,
      name: 'apuntes.pdf',
      mimeType: 'application/pdf',
      sizeBytes: 4,
      data: Uint8List.fromList([1, 2, 3, 4]),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );

    await repository.replaceAttachmentsForTask(task.id, [attachment]);

    var stored = await repository.getAllAttachments();
    expect(stored.single.id, 'att-1');
    expect(stored.single.name, 'apuntes.pdf');
    expect(stored.single.data, [1, 2, 3, 4]);

    await repository.replaceAttachmentsForTask(task.id, const []);
    stored = await repository.getAllAttachments();
    expect(stored, isEmpty);

    final tombstones = database.raw.select(
      "SELECT entity_type, entity_id FROM sync_deletions "
      "WHERE entity_type = 'attachment' AND entity_id = 'att-1';",
    );
    expect(tombstones.length, 1);
  });

  test('mueve tarea a papelera y permite restaurarla', () async {
    final task = Task(
      id: 'task-1',
      title: 'Temporal',
      createdAt: createdAt,
      updatedAt: updatedAt,
    );

    await repository.createTask(task, const [], const []);

    await repository.trashTask(task.id);
    var stored = (await repository.getAllTasks()).single;
    expect(stored.trashedAt, isNotNull);

    await repository.restoreTask(task.id);
    stored = (await repository.getAllTasks()).single;
    expect(stored.trashedAt, isNull);
  });

  test('eliminacion permanente crea tombstone', () async {
    final task = Task(
      id: 'task-1',
      title: 'Eliminar',
      createdAt: createdAt,
      updatedAt: updatedAt,
    );

    await repository.createTask(task, const [], const []);
    await repository.deleteTask(task.id);

    expect(await repository.getAllTasks(), isEmpty);

    final rows = database.raw.select(
      "SELECT entity_type, entity_id FROM sync_deletions "
      "WHERE entity_type = 'task' AND entity_id = 'task-1';",
    );

    expect(rows.length, 1);
  });

  test('eliminar una lista mueve sus tareas a inbox y registra tombstone',
      () async {
    final list = TaskList(
      id: 'custom',
      name: 'Custom',
      icon: 'list',
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
    await repository.createList(list);

    final task = Task(
      id: 'task-1',
      title: 'Mover',
      listId: 'custom',
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
    await repository.createTask(task, const [], const []);

    await repository.deleteList('custom');

    final storedTask = (await repository.getAllTasks()).single;
    expect(storedTask.listId, 'inbox');

    final rows = database.raw.select(
      "SELECT entity_type, entity_id FROM sync_deletions "
      "WHERE entity_type = 'task_list' AND entity_id = 'custom';",
    );

    expect(rows.length, 1);
  });

  test('no permite eliminar la Bandeja de entrada', () async {
    expect(
      () => repository.deleteList('inbox'),
      throwsA(isA<StateError>()),
    );
  });
}
