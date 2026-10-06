import 'dart:convert';
import 'dart:typed_data';

import '../database/local_database.dart';
import '../models/reminder.dart';
import '../models/subtask.dart';
import '../models/task.dart';
import '../models/task_attachment.dart';
import '../models/task_list.dart';

class TodoRepository {
  TodoRepository(this._database);

  final LocalDatabase _database;

  Future<List<Task>> getAllTasks() async {
    final rows = _database.readCollection('tasks');
    rows.sort((a, b) {
      final aDue = a['due_date'] as int?;
      final bDue = b['due_date'] as int?;
      if (aDue == null && bDue != null) return 1;
      if (aDue != null && bDue == null) return -1;
      if (aDue != null && bDue != null && aDue != bDue) {
        return aDue.compareTo(bDue);
      }
      return (b['created_at'] as int).compareTo(a['created_at'] as int);
    });
    return rows.map(_taskFromRow).toList(growable: false);
  }

  Future<List<TaskList>> getAllLists() async {
    final rows = _database.readCollection('task_lists');
    rows.sort((a, b) {
      if (a['id'] == 'inbox') return -1;
      if (b['id'] == 'inbox') return 1;
      return (a['name'] as String)
          .toLowerCase()
          .compareTo((b['name'] as String).toLowerCase());
    });
    return rows.map(_listFromRow).toList(growable: false);
  }

  Future<List<Subtask>> getAllSubtasks() async {
    final rows = _database.readCollection('subtasks');
    rows.sort((a, b) {
      final taskCompare =
          (a['task_id'] as String).compareTo(b['task_id'] as String);
      if (taskCompare != 0) return taskCompare;
      final positionCompare =
          (a['position'] as int).compareTo(b['position'] as int);
      if (positionCompare != 0) return positionCompare;
      return (a['created_at'] as int).compareTo(b['created_at'] as int);
    });
    return rows.map(_subtaskFromRow).toList(growable: false);
  }

  Future<List<TaskAttachment>> getAllAttachments() async {
    final rows = _database.readCollection('task_attachments');
    rows.sort(
      (a, b) => ((a['created_at'] as num?)?.toInt() ?? 0)
          .compareTo((b['created_at'] as num?)?.toInt() ?? 0),
    );
    return rows.map(_attachmentFromRow).toList(growable: false);
  }

  Future<List<Reminder>> getAllReminders() async {
    final rows = _database.readCollection('reminders');
    rows.sort((a, b) {
      final scheduleCompare =
          (a['scheduled_at'] as int).compareTo(b['scheduled_at'] as int);
      if (scheduleCompare != 0) return scheduleCompare;
      return (a['created_at'] as int).compareTo(b['created_at'] as int);
    });
    return rows.map(_reminderFromRow).toList(growable: false);
  }

  Future<void> createTask(
    Task task,
    List<Subtask> subtasks,
    List<Reminder> reminders,
  ) async {
    final tasks = _database.readCollection('tasks');
    tasks.removeWhere((item) => item['id'] == task.id);
    tasks.add(_taskToRow(task));
    _database.writeCollection('tasks', tasks);
    _replaceSubtasks(task.id, subtasks);
    _replaceReminders(task.id, reminders);
  }

  Future<void> updateTask(
    Task task,
    List<Subtask> subtasks,
    List<Reminder> reminders,
  ) async {
    await updateTaskOnly(task);
    _replaceSubtasks(task.id, subtasks);
    _replaceReminders(task.id, reminders);
  }

  Future<void> replaceAttachmentsForTask(
    String taskId,
    List<TaskAttachment> attachments,
  ) async {
    final items = _database.readCollection('task_attachments');
    final keepIds = attachments.map((item) => item.id).toSet();
    for (final item in items.where((item) => item['task_id'] == taskId)) {
      final id = item['id'] as String;
      if (!keepIds.contains(id)) {
        _recordDeletion('attachment', id);
      }
    }
    items.removeWhere((item) => item['task_id'] == taskId);

    items.addAll(
      attachments.map(
        (attachment) => <String, dynamic>{
          'id': attachment.id,
          'task_id': taskId,
          'name': attachment.name,
          'mime_type': attachment.mimeType,
          'size_bytes': attachment.sizeBytes,
          'data_base64': base64Encode(attachment.data),
          'remote_path': attachment.remotePath,
          'created_at': attachment.createdAt.millisecondsSinceEpoch,
          'updated_at': attachment.updatedAt.millisecondsSinceEpoch,
        },
      ),
    );
    _database.writeCollection('task_attachments', items);
  }

  Future<void> updateTaskOnly(Task task) async {
    final tasks = _database.readCollection('tasks');
    final index = tasks.indexWhere((item) => item['id'] == task.id);
    if (index == -1) {
      tasks.add(_taskToRow(task));
    } else {
      tasks[index] = _taskToRow(task);
    }
    _database.writeCollection('tasks', tasks);
  }

  Future<void> trashTask(String id) async {
    final tasks = _database.readCollection('tasks');
    final index = tasks.indexWhere((item) => item['id'] == id);
    if (index == -1) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    tasks[index]['trashed_at'] = now;
    tasks[index]['updated_at'] = now;
    _database.writeCollection('tasks', tasks);
  }

  Future<void> restoreTask(String id) async {
    final tasks = _database.readCollection('tasks');
    final index = tasks.indexWhere((item) => item['id'] == id);
    if (index == -1) return;
    tasks[index]['trashed_at'] = null;
    tasks[index]['updated_at'] = DateTime.now().millisecondsSinceEpoch;
    _database.writeCollection('tasks', tasks);
  }

  Future<void> deleteTask(String id) async {
    const childCollections = <String, String>{
      'subtasks': 'subtask',
      'reminders': 'reminder',
      'task_attachments': 'attachment',
    };
    for (final entry in childCollections.entries) {
      final children = _database
          .readCollection(entry.key)
          .where((item) => item['task_id'] == id);
      for (final item in children) {
        _recordDeletion(entry.value, item['id'] as String);
      }
    }
    _recordDeletion('task', id);

    final tasks = _database.readCollection('tasks')
      ..removeWhere((item) => item['id'] == id);
    final subtasks = _database.readCollection('subtasks')
      ..removeWhere((item) => item['task_id'] == id);
    final reminders = _database.readCollection('reminders')
      ..removeWhere((item) => item['task_id'] == id);
    final attachments = _database.readCollection('task_attachments')
      ..removeWhere((item) => item['task_id'] == id);

    _database.writeCollection('tasks', tasks);
    _database.writeCollection('subtasks', subtasks);
    _database.writeCollection('reminders', reminders);
    _database.writeCollection('task_attachments', attachments);
  }

  Future<void> updateSubtaskCompleted(Subtask subtask) async {
    final items = _database.readCollection('subtasks');
    final index = items.indexWhere((item) => item['id'] == subtask.id);
    if (index == -1) return;
    items[index] = _subtaskToRow(subtask);
    _database.writeCollection('subtasks', items);
  }

  Future<void> createList(TaskList list) async {
    final lists = _database.readCollection('task_lists');
    lists.removeWhere((item) => item['id'] == list.id);
    lists.add(_listToRow(list));
    _database.writeCollection('task_lists', lists);
  }

  Future<void> updateList(TaskList list) async {
    final lists = _database.readCollection('task_lists');
    final index = lists.indexWhere((item) => item['id'] == list.id);
    if (index == -1) return;
    lists[index] = _listToRow(list);
    _database.writeCollection('task_lists', lists);
  }

  Future<void> deleteList(String id) async {
    if (id == 'inbox') {
      throw StateError('La Bandeja de entrada no se puede eliminar.');
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final tasks = _database.readCollection('tasks');
    for (final task in tasks) {
      if (task['list_id'] == id) {
        task['list_id'] = 'inbox';
        task['updated_at'] = now;
      }
    }

    final lists = _database.readCollection('task_lists')
      ..removeWhere((item) => item['id'] == id);

    _recordDeletion('task_list', id, deletedAt: now);
    _database.writeCollection('tasks', tasks);
    _database.writeCollection('task_lists', lists);
  }

  void _replaceSubtasks(String taskId, List<Subtask> subtasks) {
    _recordMissingChildren(
      collection: 'subtasks',
      entityType: 'subtask',
      taskId: taskId,
      keepIds: subtasks.map((item) => item.id).toSet(),
    );

    final all = _database.readCollection('subtasks')
      ..removeWhere((item) => item['task_id'] == taskId)
      ..addAll(subtasks.map(_subtaskToRow));
    _database.writeCollection('subtasks', all);
  }

  void _replaceReminders(String taskId, List<Reminder> reminders) {
    _recordMissingChildren(
      collection: 'reminders',
      entityType: 'reminder',
      taskId: taskId,
      keepIds: reminders.map((item) => item.id).toSet(),
    );

    final all = _database.readCollection('reminders')
      ..removeWhere((item) => item['task_id'] == taskId)
      ..addAll(reminders.map(_reminderToRow));
    _database.writeCollection('reminders', all);
  }

  void _recordMissingChildren({
    required String collection,
    required String entityType,
    required String taskId,
    required Set<String> keepIds,
  }) {
    final deletedAt = DateTime.now().millisecondsSinceEpoch;
    for (final row in _database.readCollection(collection)) {
      if (row['task_id'] == taskId && !keepIds.contains(row['id'])) {
        _recordDeletion(
          entityType,
          row['id'] as String,
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
    final journal = _database.readCollection('sync_deletions');
    final timestamp = deletedAt ?? DateTime.now().millisecondsSinceEpoch;
    final index = journal.indexWhere(
      (item) =>
          item['entity_type'] == entityType && item['entity_id'] == entityId,
    );

    final row = <String, dynamic>{
      'entity_type': entityType,
      'entity_id': entityId,
      'deleted_at': timestamp,
    };

    if (index == -1) {
      journal.add(row);
    } else if ((journal[index]['deleted_at'] as int) < timestamp) {
      journal[index] = row;
    }

    _database.writeCollection('sync_deletions', journal);
  }

  Map<String, dynamic> _taskToRow(Task task) => <String, dynamic>{
        'id': task.id,
        'title': task.title,
        'description': task.description,
        'priority': task.priority.index,
        'due_date': task.dueDate?.millisecondsSinceEpoch,
        'completed': task.completed,
        'list_id': task.listId,
        'trashed_at': task.trashedAt?.millisecondsSinceEpoch,
        'created_at': task.createdAt.millisecondsSinceEpoch,
        'updated_at': task.updatedAt.millisecondsSinceEpoch,
      };

  Map<String, dynamic> _listToRow(TaskList list) => <String, dynamic>{
        'id': list.id,
        'name': list.name,
        'icon': list.icon,
        'is_system': list.isSystem,
        'created_at': list.createdAt.millisecondsSinceEpoch,
        'updated_at': list.updatedAt.millisecondsSinceEpoch,
      };

  Map<String, dynamic> _subtaskToRow(Subtask item) => <String, dynamic>{
        'id': item.id,
        'task_id': item.taskId,
        'title': item.title,
        'completed': item.completed,
        'position': item.position,
        'created_at': item.createdAt.millisecondsSinceEpoch,
        'updated_at': item.updatedAt.millisecondsSinceEpoch,
      };

  Map<String, dynamic> _reminderToRow(Reminder item) => <String, dynamic>{
        'id': item.id,
        'task_id': item.taskId,
        'scheduled_at': item.scheduledAt.millisecondsSinceEpoch,
        'offset_minutes': item.offsetMinutes,
        'enabled': item.enabled,
        'created_at': item.createdAt.millisecondsSinceEpoch,
        'updated_at': item.updatedAt.millisecondsSinceEpoch,
      };

  Task _taskFromRow(Map<String, dynamic> row) {
    final priorityIndex = (row['priority'] as num?)?.toInt() ?? 0;
    final safePriority =
        priorityIndex >= 0 && priorityIndex < TaskPriority.values.length
            ? TaskPriority.values[priorityIndex]
            : TaskPriority.none;
    final dueDateValue = (row['due_date'] as num?)?.toInt();
    final trashedAtValue = (row['trashed_at'] as num?)?.toInt();

    return Task(
      id: row['id'] as String,
      title: row['title'] as String,
      description: (row['description'] as String?) ?? '',
      priority: safePriority,
      dueDate: dueDateValue == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(dueDateValue),
      completed: (row['completed'] as bool?) ?? false,
      listId: (row['list_id'] as String?) ?? 'inbox',
      trashedAt: trashedAtValue == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(trashedAtValue),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (row['created_at'] as num).toInt(),
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (row['updated_at'] as num).toInt(),
      ),
    );
  }

  TaskList _listFromRow(Map<String, dynamic> row) {
    return TaskList(
      id: row['id'] as String,
      name: row['name'] as String,
      icon: (row['icon'] as String?) ?? 'list',
      isSystem: (row['is_system'] as bool?) ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (row['created_at'] as num).toInt(),
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (row['updated_at'] as num).toInt(),
      ),
    );
  }

  Subtask _subtaskFromRow(Map<String, dynamic> row) {
    return Subtask(
      id: row['id'] as String,
      taskId: row['task_id'] as String,
      title: row['title'] as String,
      completed: (row['completed'] as bool?) ?? false,
      position: (row['position'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (row['created_at'] as num).toInt(),
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (row['updated_at'] as num).toInt(),
      ),
    );
  }

  Reminder _reminderFromRow(Map<String, dynamic> row) {
    return Reminder(
      id: row['id'] as String,
      taskId: row['task_id'] as String,
      scheduledAt: DateTime.fromMillisecondsSinceEpoch(
        (row['scheduled_at'] as num).toInt(),
      ),
      offsetMinutes: (row['offset_minutes'] as num?)?.toInt(),
      enabled: (row['enabled'] as bool?) ?? true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (row['created_at'] as num).toInt(),
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (row['updated_at'] as num).toInt(),
      ),
    );
  }
  TaskAttachment _attachmentFromRow(Map<String, dynamic> row) {
    return TaskAttachment(
      id: row['id'] as String,
      taskId: row['task_id'] as String,
      name: row['name'] as String,
      mimeType: row['mime_type'] as String,
      sizeBytes: (row['size_bytes'] as num?)?.toInt() ?? 0,
      data: Uint8List.fromList(
        base64Decode((row['data_base64'] as String?) ?? ''),
      ),
      remotePath: row['remote_path'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (row['created_at'] as num).toInt(),
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (row['updated_at'] as num).toInt(),
      ),
    );
  }

}
