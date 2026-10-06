import 'dart:typed_data';

import '../database/local_database_native.dart';
import '../models/reminder.dart';
import '../models/subtask.dart';
import '../models/task.dart';
import '../models/task_attachment.dart';
import '../models/task_list.dart';

class TodoRepository {
  TodoRepository(this._database);

  final LocalDatabase _database;

  Future<List<Task>> getAllTasks() async {
    final rows = _database.raw.select('''
      SELECT
        id,
        title,
        description,
        priority,
        due_date,
        completed,
        list_id,
        trashed_at,
        created_at,
        updated_at
      FROM tasks
      ORDER BY
        CASE WHEN due_date IS NULL THEN 1 ELSE 0 END,
        due_date ASC,
        created_at DESC;
    ''');

    return rows.map(_taskFromRow).toList(growable: false);
  }

  Future<List<TaskList>> getAllLists() async {
    final rows = _database.raw.select('''
      SELECT
        id,
        name,
        icon,
        is_system,
        created_at,
        updated_at
      FROM task_lists
      ORDER BY
        CASE WHEN id = 'inbox' THEN 0 ELSE 1 END,
        LOWER(name) ASC;
    ''');

    return rows.map(_listFromRow).toList(growable: false);
  }

  Future<List<Subtask>> getAllSubtasks() async {
    final rows = _database.raw.select('''
      SELECT
        id,
        task_id,
        title,
        completed,
        position,
        created_at,
        updated_at
      FROM subtasks
      ORDER BY task_id ASC, position ASC, created_at ASC;
    ''');

    return rows.map(_subtaskFromRow).toList(growable: false);
  }

  Future<List<TaskAttachment>> getAllAttachments() async {
    final rows = _database.raw.select('''
      SELECT
        id,
        task_id,
        name,
        mime_type,
        size_bytes,
        data,
        remote_path,
        created_at,
        updated_at
      FROM task_attachments
      ORDER BY created_at ASC;
    ''');

    return rows.map(_attachmentFromRow).toList(growable: false);
  }

  Future<List<Reminder>> getAllReminders() async {
    final rows = _database.raw.select('''
      SELECT
        id,
        task_id,
        scheduled_at,
        offset_minutes,
        enabled,
        created_at,
        updated_at
      FROM reminders
      ORDER BY scheduled_at ASC, created_at ASC;
    ''');

    return rows.map(_reminderFromRow).toList(growable: false);
  }

  Future<void> createTask(
    Task task,
    List<Subtask> subtasks,
    List<Reminder> reminders,
  ) async {
    _database.raw.execute('BEGIN IMMEDIATE;');

    try {
      _insertTask(task);
      _replaceSubtasks(task.id, subtasks);
      _replaceReminders(task.id, reminders);
      _database.raw.execute('COMMIT;');
    } catch (_) {
      _database.raw.execute('ROLLBACK;');
      rethrow;
    }
  }

  Future<void> updateTask(
    Task task,
    List<Subtask> subtasks,
    List<Reminder> reminders,
  ) async {
    _database.raw.execute('BEGIN IMMEDIATE;');

    try {
      final statement = _database.raw.prepare('''
        UPDATE tasks
        SET
          title = ?,
          description = ?,
          priority = ?,
          due_date = ?,
          completed = ?,
          list_id = ?,
          trashed_at = ?,
          updated_at = ?
        WHERE id = ?;
      ''');

      try {
        statement.execute([
          task.title,
          task.description,
          task.priority.index,
          task.dueDate?.millisecondsSinceEpoch,
          task.completed ? 1 : 0,
          task.listId,
          task.trashedAt?.millisecondsSinceEpoch,
          task.updatedAt.millisecondsSinceEpoch,
          task.id,
        ]);
      } finally {
        statement.close();
      }

      _replaceSubtasks(task.id, subtasks);
      _replaceReminders(task.id, reminders);
      _database.raw.execute('COMMIT;');
    } catch (_) {
      _database.raw.execute('ROLLBACK;');
      rethrow;
    }
  }

  Future<void> replaceAttachmentsForTask(
    String taskId,
    List<TaskAttachment> attachments,
  ) async {
    _database.raw.execute('BEGIN IMMEDIATE;');
    _recordMissingChildren(
      table: 'task_attachments',
      entityType: 'attachment',
      taskId: taskId,
      keepIds: attachments.map((item) => item.id).toSet(),
    );
    try {
      final deleteStatement = _database.raw.prepare(
        'DELETE FROM task_attachments WHERE task_id = ?;',
      );
      try {
        deleteStatement.execute([taskId]);
      } finally {
        deleteStatement.close();
      }

      if (attachments.isNotEmpty) {
        final insertStatement = _database.raw.prepare('''
          INSERT INTO task_attachments (
            id,
            task_id,
            name,
            mime_type,
            size_bytes,
            data,
            remote_path,
            created_at,
            updated_at
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);
        ''');
        try {
          for (final attachment in attachments) {
            insertStatement.execute([
              attachment.id,
              taskId,
              attachment.name,
              attachment.mimeType,
              attachment.sizeBytes,
              attachment.data,
              attachment.remotePath,
              attachment.createdAt.millisecondsSinceEpoch,
              attachment.updatedAt.millisecondsSinceEpoch,
            ]);
          }
        } finally {
          insertStatement.close();
        }
      }
      _database.raw.execute('COMMIT;');
    } catch (_) {
      _database.raw.execute('ROLLBACK;');
      rethrow;
    }
  }

  Future<void> updateTaskOnly(Task task) async {
    final statement = _database.raw.prepare('''
      UPDATE tasks
      SET
        title = ?,
        description = ?,
        priority = ?,
        due_date = ?,
        completed = ?,
        list_id = ?,
        trashed_at = ?,
        updated_at = ?
      WHERE id = ?;
    ''');

    try {
      statement.execute([
        task.title,
        task.description,
        task.priority.index,
        task.dueDate?.millisecondsSinceEpoch,
        task.completed ? 1 : 0,
        task.listId,
        task.trashedAt?.millisecondsSinceEpoch,
        task.updatedAt.millisecondsSinceEpoch,
        task.id,
      ]);
    } finally {
      statement.close();
    }
  }

  Future<void> trashTask(String id) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final statement = _database.raw.prepare('''
      UPDATE tasks
      SET trashed_at = ?, updated_at = ?
      WHERE id = ?;
    ''');
    try {
      statement.execute([now, now, id]);
    } finally {
      statement.close();
    }
  }

  Future<void> restoreTask(String id) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final statement = _database.raw.prepare('''
      UPDATE tasks
      SET trashed_at = NULL, updated_at = ?
      WHERE id = ?;
    ''');
    try {
      statement.execute([now, id]);
    } finally {
      statement.close();
    }
  }

  Future<void> deleteTask(String id) async {
    _database.raw.execute('BEGIN IMMEDIATE;');

    try {
      _recordDeletion('task', id);
      final attachmentRows = _database.raw.select(
        'SELECT id FROM task_attachments WHERE task_id = ?;',
        [id],
      );
      for (final row in attachmentRows) {
        _recordDeletion('attachment', row['id']! as String);
      }

      final subtaskStatement =
          _database.raw.prepare('DELETE FROM subtasks WHERE task_id = ?;');
      try {
        subtaskStatement.execute([id]);
      } finally {
        subtaskStatement.close();
      }

      final taskStatement =
          _database.raw.prepare('DELETE FROM tasks WHERE id = ?;');
      try {
        taskStatement.execute([id]);
      } finally {
        taskStatement.close();
      }

      _database.raw.execute('COMMIT;');
    } catch (_) {
      _database.raw.execute('ROLLBACK;');
      rethrow;
    }
  }

  Future<void> updateSubtaskCompleted(Subtask subtask) async {
    final statement = _database.raw.prepare('''
      UPDATE subtasks
      SET completed = ?, updated_at = ?
      WHERE id = ?;
    ''');

    try {
      statement.execute([
        subtask.completed ? 1 : 0,
        subtask.updatedAt.millisecondsSinceEpoch,
        subtask.id,
      ]);
    } finally {
      statement.close();
    }
  }

  Future<void> createList(TaskList list) async {
    final statement = _database.raw.prepare('''
      INSERT INTO task_lists (
        id,
        name,
        icon,
        is_system,
        created_at,
        updated_at
      ) VALUES (?, ?, ?, ?, ?, ?);
    ''');

    try {
      statement.execute([
        list.id,
        list.name,
        list.icon,
        list.isSystem ? 1 : 0,
        list.createdAt.millisecondsSinceEpoch,
        list.updatedAt.millisecondsSinceEpoch,
      ]);
    } finally {
      statement.close();
    }
  }

  Future<void> updateList(TaskList list) async {
    final statement = _database.raw.prepare('''
      UPDATE task_lists
      SET name = ?, icon = ?, updated_at = ?
      WHERE id = ?;
    ''');

    try {
      statement.execute([
        list.name,
        list.icon,
        list.updatedAt.millisecondsSinceEpoch,
        list.id,
      ]);
    } finally {
      statement.close();
    }
  }

  Future<void> deleteList(String id) async {
    if (id == 'inbox') {
      throw StateError('La Bandeja de entrada no se puede eliminar.');
    }

    _database.raw.execute('BEGIN IMMEDIATE;');

    try {
      final moveStatement = _database.raw.prepare('''
        UPDATE tasks
        SET list_id = 'inbox', updated_at = ?
        WHERE list_id = ?;
      ''');
      try {
        moveStatement.execute([
          DateTime.now().millisecondsSinceEpoch,
          id,
        ]);
      } finally {
        moveStatement.close();
      }

      _recordDeletion('task_list', id);

      final deleteStatement =
          _database.raw.prepare('DELETE FROM task_lists WHERE id = ?;');
      try {
        deleteStatement.execute([id]);
      } finally {
        deleteStatement.close();
      }

      _database.raw.execute('COMMIT;');
    } catch (_) {
      _database.raw.execute('ROLLBACK;');
      rethrow;
    }
  }

  void _insertTask(Task task) {
    final statement = _database.raw.prepare('''
      INSERT INTO tasks (
        id,
        title,
        description,
        priority,
        due_date,
        completed,
        list_id,
        trashed_at,
        created_at,
        updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    ''');

    try {
      statement.execute([
        task.id,
        task.title,
        task.description,
        task.priority.index,
        task.dueDate?.millisecondsSinceEpoch,
        task.completed ? 1 : 0,
        task.listId,
        task.trashedAt?.millisecondsSinceEpoch,
        task.createdAt.millisecondsSinceEpoch,
        task.updatedAt.millisecondsSinceEpoch,
      ]);
    } finally {
      statement.close();
    }
  }

  void _replaceSubtasks(String taskId, List<Subtask> subtasks) {
    _recordMissingChildren(
      table: 'subtasks',
      entityType: 'subtask',
      taskId: taskId,
      keepIds: subtasks.map((item) => item.id).toSet(),
    );

    final deleteStatement =
        _database.raw.prepare('DELETE FROM subtasks WHERE task_id = ?;');
    try {
      deleteStatement.execute([taskId]);
    } finally {
      deleteStatement.close();
    }

    if (subtasks.isEmpty) return;

    final insertStatement = _database.raw.prepare('''
      INSERT INTO subtasks (
        id,
        task_id,
        title,
        completed,
        position,
        created_at,
        updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?);
    ''');

    try {
      for (final subtask in subtasks) {
        insertStatement.execute([
          subtask.id,
          taskId,
          subtask.title,
          subtask.completed ? 1 : 0,
          subtask.position,
          subtask.createdAt.millisecondsSinceEpoch,
          subtask.updatedAt.millisecondsSinceEpoch,
        ]);
      }
    } finally {
      insertStatement.close();
    }
  }

  void _replaceReminders(String taskId, List<Reminder> reminders) {
    _recordMissingChildren(
      table: 'reminders',
      entityType: 'reminder',
      taskId: taskId,
      keepIds: reminders.map((item) => item.id).toSet(),
    );

    final deleteStatement =
        _database.raw.prepare('DELETE FROM reminders WHERE task_id = ?;');
    try {
      deleteStatement.execute([taskId]);
    } finally {
      deleteStatement.close();
    }

    if (reminders.isEmpty) return;

    final insertStatement = _database.raw.prepare('''
      INSERT INTO reminders (
        id,
        task_id,
        scheduled_at,
        offset_minutes,
        enabled,
        created_at,
        updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?);
    ''');

    try {
      for (final reminder in reminders) {
        insertStatement.execute([
          reminder.id,
          taskId,
          reminder.scheduledAt.millisecondsSinceEpoch,
          reminder.offsetMinutes,
          reminder.enabled ? 1 : 0,
          reminder.createdAt.millisecondsSinceEpoch,
          reminder.updatedAt.millisecondsSinceEpoch,
        ]);
      }
    } finally {
      insertStatement.close();
    }
  }

  void _recordMissingChildren({
    required String table,
    required String entityType,
    required String taskId,
    required Set<String> keepIds,
  }) {
    final rows = _database.raw.select(
      'SELECT id FROM $table WHERE task_id = ?;',
      [taskId],
    );

    final deletedAt = DateTime.now().millisecondsSinceEpoch;
    for (final row in rows) {
      final id = row['id']! as String;
      if (!keepIds.contains(id)) {
        _recordDeletion(
          entityType,
          id,
          deletedAt: deletedAt,
        );
      }
    }
  }

  void _recordDeletion(
    String entityType,
    String entityId, {
    int? deletedAt,
  }) {
    final statement = _database.raw.prepare('''
      INSERT INTO sync_deletions (
        entity_type,
        entity_id,
        deleted_at
      ) VALUES (?, ?, ?)
      ON CONFLICT(entity_type, entity_id) DO UPDATE SET
        deleted_at = excluded.deleted_at
      WHERE excluded.deleted_at > sync_deletions.deleted_at;
    ''');

    try {
      statement.execute([
        entityType,
        entityId,
        deletedAt ?? DateTime.now().millisecondsSinceEpoch,
      ]);
    } finally {
      statement.close();
    }
  }

  Task _taskFromRow(Map<String, Object?> row) {
    final priorityIndex = (row['priority'] as int?) ?? 0;
    final safePriority =
        priorityIndex >= 0 && priorityIndex < TaskPriority.values.length
            ? TaskPriority.values[priorityIndex]
            : TaskPriority.none;

    final dueDateValue = row['due_date'] as int?;

    return Task(
      id: row['id']! as String,
      title: row['title']! as String,
      description: (row['description'] as String?) ?? '',
      priority: safePriority,
      dueDate: dueDateValue == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(dueDateValue),
      completed: ((row['completed'] as int?) ?? 0) == 1,
      listId: (row['list_id'] as String?) ?? 'inbox',
      trashedAt: row['trashed_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row['trashed_at']! as int),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row['created_at']! as int,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row['updated_at']! as int,
      ),
    );
  }

  TaskList _listFromRow(Map<String, Object?> row) {
    return TaskList(
      id: row['id']! as String,
      name: row['name']! as String,
      icon: (row['icon'] as String?) ?? 'list',
      isSystem: ((row['is_system'] as int?) ?? 0) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row['created_at']! as int,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row['updated_at']! as int,
      ),
    );
  }

  Subtask _subtaskFromRow(Map<String, Object?> row) {
    return Subtask(
      id: row['id']! as String,
      taskId: row['task_id']! as String,
      title: row['title']! as String,
      completed: ((row['completed'] as int?) ?? 0) == 1,
      position: (row['position'] as int?) ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row['created_at']! as int,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row['updated_at']! as int,
      ),
    );
  }

  TaskAttachment _attachmentFromRow(Map<String, Object?> row) {
    final rawData = row['data'];
    return TaskAttachment(
      id: row['id']! as String,
      taskId: row['task_id']! as String,
      name: row['name']! as String,
      mimeType: row['mime_type']! as String,
      sizeBytes: (row['size_bytes'] as int?) ?? 0,
      data: rawData is List<int>
          ? Uint8List.fromList(rawData)
          : (rawData as Uint8List),
      remotePath: row['remote_path'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row['created_at']! as int,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row['updated_at']! as int,
      ),
    );
  }

  Reminder _reminderFromRow(Map<String, Object?> row) {
    return Reminder(
      id: row['id']! as String,
      taskId: row['task_id']! as String,
      scheduledAt: DateTime.fromMillisecondsSinceEpoch(
        row['scheduled_at']! as int,
      ),
      offsetMinutes: row['offset_minutes'] as int?,
      enabled: ((row['enabled'] as int?) ?? 1) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row['created_at']! as int,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row['updated_at']! as int,
      ),
    );
  }
}
