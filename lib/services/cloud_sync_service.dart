import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/local_database.dart';
import '../repositories/todo_repository.dart';

class CloudUploadResult {
  const CloudUploadResult({
    required this.lists,
    required this.tasks,
    required this.subtasks,
    required this.reminders,
  });

  final int lists;
  final int tasks;
  final int subtasks;
  final int reminders;

  int get total => lists + tasks + subtasks + reminders;
}

class CloudSyncService {
  CloudSyncService({
    required SupabaseClient? client,
    required TodoRepository repository,
    required LocalDatabase database,
  })  : _client = client,
        _repository = repository,
        _database = database;

  final SupabaseClient? _client;
  final TodoRepository _repository;
  final LocalDatabase _database;

  bool get isConfigured => _client != null;

  Future<CloudUploadResult> uploadLocalSnapshot() async {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase no está configurado.');
    }

    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('No hay una sesión iniciada.');
    }

    final userId = user.id;
    final lists = await _repository.getAllLists();
    final tasks = await _repository.getAllTasks();
    final subtasks = await _repository.getAllSubtasks();
    final reminders = await _repository.getAllReminders();

    if (lists.isNotEmpty) {
      await client.from('task_lists').upsert(
        lists
            .map(
              (list) => <String, dynamic>{
                'user_id': userId,
                'id': list.id,
                'name': list.name,
                'icon': list.icon,
                'is_system': list.isSystem,
                'created_at': _iso(list.createdAt),
                'updated_at': _iso(list.updatedAt),
              },
            )
            .toList(growable: false),
        onConflict: 'user_id,id',
      );
    }

    if (tasks.isNotEmpty) {
      await client.from('tasks').upsert(
        tasks
            .map(
              (task) => <String, dynamic>{
                'user_id': userId,
                'id': task.id,
                'title': task.title,
                'description': task.description,
                'priority': task.priority.index,
                'due_date': task.dueDate == null ? null : _iso(task.dueDate!),
                'completed': task.completed,
                'list_id': task.listId,
                'created_at': _iso(task.createdAt),
                'updated_at': _iso(task.updatedAt),
              },
            )
            .toList(growable: false),
        onConflict: 'user_id,id',
      );
    }

    if (subtasks.isNotEmpty) {
      await client.from('subtasks').upsert(
        subtasks
            .map(
              (subtask) => <String, dynamic>{
                'user_id': userId,
                'id': subtask.id,
                'task_id': subtask.taskId,
                'title': subtask.title,
                'completed': subtask.completed,
                'position': subtask.position,
                'created_at': _iso(subtask.createdAt),
                'updated_at': _iso(subtask.updatedAt),
              },
            )
            .toList(growable: false),
        onConflict: 'user_id,id',
      );
    }

    if (reminders.isNotEmpty) {
      await client.from('reminders').upsert(
        reminders
            .map(
              (reminder) => <String, dynamic>{
                'user_id': userId,
                'id': reminder.id,
                'task_id': reminder.taskId,
                'scheduled_at': _iso(reminder.scheduledAt),
                'offset_minutes': reminder.offsetMinutes,
                'enabled': reminder.enabled,
                'created_at': _iso(reminder.createdAt),
                'updated_at': _iso(reminder.updatedAt),
              },
            )
            .toList(growable: false),
        onConflict: 'user_id,id',
      );
    }

    final themeId = _database.getSetting('theme_id') ?? 'emilia';
    await client.from('user_preferences').upsert(
      <String, dynamic>{
        'user_id': userId,
        'theme_id': themeId,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'user_id',
    );

    _database.setSetting(
      'last_cloud_upload_at',
      DateTime.now().toUtc().toIso8601String(),
    );

    return CloudUploadResult(
      lists: lists.length,
      tasks: tasks.length,
      subtasks: subtasks.length,
      reminders: reminders.length,
    );
  }

  String _iso(DateTime value) => value.toUtc().toIso8601String();
}
