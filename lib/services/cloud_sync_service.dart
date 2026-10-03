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

class CloudSyncResult {
  const CloudSyncResult({
    required this.remoteLists,
    required this.remoteTasks,
    required this.remoteSubtasks,
    required this.remoteReminders,
    required this.remoteDeletions,
    required this.themeId,
    required this.uploaded,
  });

  final int remoteLists;
  final int remoteTasks;
  final int remoteSubtasks;
  final int remoteReminders;
  final int remoteDeletions;
  final String themeId;
  final CloudUploadResult uploaded;

  int get remoteTotal =>
      remoteLists +
      remoteTasks +
      remoteSubtasks +
      remoteReminders +
      remoteDeletions;
}

class CloudSyncService {
  CloudSyncService({
    required this._client,
    required this._repository,
    required this._database,
  });

  final SupabaseClient? _client;
  final TodoRepository _repository;
  final LocalDatabase _database;

  bool get isConfigured => _client != null;

  RealtimeChannel? subscribeToRemoteChanges(void Function() onChange) {
    final client = _client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return null;

    final channel = client
        .channel('orbitask:${user.id}:changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          callback: (_) => onChange(),
        );

    channel.subscribe();
    return channel;
  }

  Future<CloudSyncResult> syncNow() async {
    final client = _requireClient();
    final user = _requireUser(client);
    _requireWorkspaceOwner(user.id);

    final themeId = await _syncThemePreference(client, user.id);

    final remoteDeletions = await client
        .from('sync_deletions')
        .select()
        .eq('user_id', user.id);

    _mergeRemoteDeletions(remoteDeletions);

    final remoteLists = await client
        .from('task_lists')
        .select()
        .eq('user_id', user.id);
    final remoteTasks =
        await client.from('tasks').select().eq('user_id', user.id);
    final remoteSubtasks =
        await client.from('subtasks').select().eq('user_id', user.id);
    final remoteReminders =
        await client.from('reminders').select().eq('user_id', user.id);

    _mergeRemoteSnapshot(
      lists: remoteLists,
      tasks: remoteTasks,
      subtasks: remoteSubtasks,
      reminders: remoteReminders,
    );

    _applyLocalDeletionJournal();

    final uploaded = await uploadLocalSnapshot();
    await _uploadDeletionJournal(client, user.id);
    await _applyDeletionJournalToCloud(client, user.id);

    _database.setSetting(
      'last_cloud_sync_at',
      DateTime.now().toUtc().toIso8601String(),
    );

    return CloudSyncResult(
      remoteLists: remoteLists.length,
      remoteTasks: remoteTasks.length,
      remoteSubtasks: remoteSubtasks.length,
      remoteReminders: remoteReminders.length,
      remoteDeletions: remoteDeletions.length,
      themeId: themeId,
      uploaded: uploaded,
    );
  }

  Future<CloudUploadResult> uploadLocalSnapshot() async {
    final client = _requireClient();
    final user = _requireUser(client);
    _requireWorkspaceOwner(user.id);
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
                'due_date':
                    task.dueDate == null ? null : _iso(task.dueDate!),
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

  Future<String> _syncThemePreference(
    SupabaseClient client,
    String userId,
  ) async {
    final remotePreferences = await client
        .from('user_preferences')
        .select('theme_id, updated_at')
        .eq('user_id', userId)
        .limit(1);

    final remote =
        remotePreferences.isEmpty ? null : remotePreferences.first;

    var localThemeId = _database.getSetting('theme_id') ?? 'emilia';
    var localUpdatedAt = int.tryParse(
          _database.getSetting('theme_updated_at') ?? '',
        ) ??
        0;

    var remoteUpdatedAt = 0;
    if (remote != null) {
      remoteUpdatedAt = _millis(remote['updated_at']);
      final remoteThemeId = (remote['theme_id'] as String?) ?? 'emilia';

      if (remoteUpdatedAt > localUpdatedAt) {
        localThemeId = remoteThemeId;
        localUpdatedAt = remoteUpdatedAt;
        _database.setSetting('theme_id', localThemeId);
        _database.setSetting(
          'theme_updated_at',
          localUpdatedAt.toString(),
        );
      }
    }

    if (localUpdatedAt == 0) {
      localUpdatedAt = DateTime.now().millisecondsSinceEpoch;
      _database.setSetting(
        'theme_updated_at',
        localUpdatedAt.toString(),
      );
    }

    if (remote == null || localUpdatedAt > remoteUpdatedAt) {
      await client.from('user_preferences').upsert(
        <String, dynamic>{
          'user_id': userId,
          'theme_id': localThemeId,
          'updated_at': DateTime.fromMillisecondsSinceEpoch(
            localUpdatedAt,
            isUtc: true,
          ).toIso8601String(),
        },
        onConflict: 'user_id',
      );
    }

    return localThemeId;
  }

  void _mergeRemoteSnapshot({
    required List<Map<String, dynamic>> lists,
    required List<Map<String, dynamic>> tasks,
    required List<Map<String, dynamic>> subtasks,
    required List<Map<String, dynamic>> reminders,
  }) {
    final database = _database.raw;
    database.execute('BEGIN IMMEDIATE;');

    try {
      final listStatement = database.prepare('''
        INSERT INTO task_lists (
          id, name, icon, is_system, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET
          name = excluded.name,
          icon = excluded.icon,
          is_system = excluded.is_system,
          updated_at = excluded.updated_at
        WHERE excluded.updated_at > task_lists.updated_at;
      ''');

      final taskStatement = database.prepare('''
        INSERT INTO tasks (
          id, title, description, priority, due_date, completed,
          list_id, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET
          title = excluded.title,
          description = excluded.description,
          priority = excluded.priority,
          due_date = excluded.due_date,
          completed = excluded.completed,
          list_id = excluded.list_id,
          updated_at = excluded.updated_at
        WHERE excluded.updated_at > tasks.updated_at;
      ''');

      final subtaskStatement = database.prepare('''
        INSERT INTO subtasks (
          id, task_id, title, completed, position, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET
          task_id = excluded.task_id,
          title = excluded.title,
          completed = excluded.completed,
          position = excluded.position,
          updated_at = excluded.updated_at
        WHERE excluded.updated_at > subtasks.updated_at;
      ''');

      final reminderStatement = database.prepare('''
        INSERT INTO reminders (
          id, task_id, scheduled_at, offset_minutes, enabled,
          created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET
          task_id = excluded.task_id,
          scheduled_at = excluded.scheduled_at,
          offset_minutes = excluded.offset_minutes,
          enabled = excluded.enabled,
          updated_at = excluded.updated_at
        WHERE excluded.updated_at > reminders.updated_at;
      ''');

      try {
        for (final row in lists) {
          listStatement.execute([
            row['id']! as String,
            row['name']! as String,
            (row['icon'] as String?) ?? 'list',
            ((row['is_system'] as bool?) ?? false) ? 1 : 0,
            _millis(row['created_at']),
            _millis(row['updated_at']),
          ]);
        }

        for (final row in tasks) {
          taskStatement.execute([
            row['id']! as String,
            row['title']! as String,
            (row['description'] as String?) ?? '',
            (row['priority'] as num?)?.toInt() ?? 0,
            _nullableMillis(row['due_date']),
            ((row['completed'] as bool?) ?? false) ? 1 : 0,
            (row['list_id'] as String?) ?? 'inbox',
            _millis(row['created_at']),
            _millis(row['updated_at']),
          ]);
        }

        for (final row in subtasks) {
          subtaskStatement.execute([
            row['id']! as String,
            row['task_id']! as String,
            row['title']! as String,
            ((row['completed'] as bool?) ?? false) ? 1 : 0,
            (row['position'] as num?)?.toInt() ?? 0,
            _millis(row['created_at']),
            _millis(row['updated_at']),
          ]);
        }

        for (final row in reminders) {
          reminderStatement.execute([
            row['id']! as String,
            row['task_id']! as String,
            _millis(row['scheduled_at']),
            (row['offset_minutes'] as num?)?.toInt(),
            ((row['enabled'] as bool?) ?? true) ? 1 : 0,
            _millis(row['created_at']),
            _millis(row['updated_at']),
          ]);
        }
      } finally {
        listStatement.close();
        taskStatement.close();
        subtaskStatement.close();
        reminderStatement.close();
      }

      database.execute('COMMIT;');
    } catch (_) {
      database.execute('ROLLBACK;');
      rethrow;
    }
  }

  void _mergeRemoteDeletions(List<Map<String, dynamic>> remote) {
    if (remote.isEmpty) return;

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
      for (final row in remote) {
        statement.execute([
          row['entity_type']! as String,
          row['entity_id']! as String,
          _millis(row['deleted_at']),
        ]);
      }
    } finally {
      statement.close();
    }
  }

  void _applyLocalDeletionJournal() {
    final database = _database.raw;
    final rows = database.select('''
      SELECT entity_type, entity_id, deleted_at
      FROM sync_deletions
      ORDER BY deleted_at ASC;
    ''');

    database.execute('BEGIN IMMEDIATE;');

    try {
      for (final row in rows) {
        final type = row['entity_type']! as String;
        final id = row['entity_id']! as String;
        final deletedAt = row['deleted_at']! as int;

        switch (type) {
          case 'task':
            _deleteLocalIfNotNewer('tasks', id, deletedAt);
            break;
          case 'subtask':
            _deleteLocalIfNotNewer('subtasks', id, deletedAt);
            break;
          case 'reminder':
            _deleteLocalIfNotNewer('reminders', id, deletedAt);
            break;
          case 'task_list':
            if (id != 'inbox') {
              final listRows = database.select(
                'SELECT updated_at FROM task_lists WHERE id = ? LIMIT 1;',
                [id],
              );
              final canDelete = listRows.isEmpty ||
                  (listRows.first['updated_at']! as int) <= deletedAt;

              if (canDelete) {
                final moveStatement = database.prepare('''
                  UPDATE tasks
                  SET list_id = 'inbox', updated_at = ?
                  WHERE list_id = ?;
                ''');
                try {
                  moveStatement.execute([deletedAt, id]);
                } finally {
                  moveStatement.close();
                }
                _deleteLocalIfNotNewer('task_lists', id, deletedAt);
              }
            }
            break;
        }
      }

      database.execute('COMMIT;');
    } catch (_) {
      database.execute('ROLLBACK;');
      rethrow;
    }
  }

  void _deleteLocalIfNotNewer(
    String table,
    String id,
    int deletedAt,
  ) {
    final statement = _database.raw.prepare(
      'DELETE FROM $table WHERE id = ? AND updated_at <= ?;',
    );
    try {
      statement.execute([id, deletedAt]);
    } finally {
      statement.close();
    }
  }

  Future<void> _uploadDeletionJournal(
    SupabaseClient client,
    String userId,
  ) async {
    final rows = _database.raw.select('''
      SELECT entity_type, entity_id, deleted_at
      FROM sync_deletions;
    ''');

    if (rows.isEmpty) return;

    await client.from('sync_deletions').upsert(
      rows
          .map(
            (row) => <String, dynamic>{
              'user_id': userId,
              'entity_type': row['entity_type']! as String,
              'entity_id': row['entity_id']! as String,
              'deleted_at': DateTime.fromMillisecondsSinceEpoch(
                row['deleted_at']! as int,
                isUtc: true,
              ).toIso8601String(),
            },
          )
          .toList(growable: false),
      onConflict: 'user_id,entity_type,entity_id',
    );
  }

  Future<void> _applyDeletionJournalToCloud(
    SupabaseClient client,
    String userId,
  ) async {
    final rows = _database.raw.select('''
      SELECT entity_type, entity_id, deleted_at
      FROM sync_deletions
      ORDER BY deleted_at ASC;
    ''');

    for (final row in rows) {
      final type = row['entity_type']! as String;
      final id = row['entity_id']! as String;
      final deletedAt = DateTime.fromMillisecondsSinceEpoch(
        row['deleted_at']! as int,
        isUtc: true,
      ).toIso8601String();

      switch (type) {
        case 'reminder':
          await _deleteCloudIfNotNewer(
            client,
            'reminders',
            userId,
            id,
            deletedAt,
          );
          break;
        case 'subtask':
          await _deleteCloudIfNotNewer(
            client,
            'subtasks',
            userId,
            id,
            deletedAt,
          );
          break;
        case 'task':
          await _deleteCloudIfNotNewer(
            client,
            'tasks',
            userId,
            id,
            deletedAt,
          );
          break;
        case 'task_list':
          if (id != 'inbox') {
            await _deleteCloudIfNotNewer(
              client,
              'task_lists',
              userId,
              id,
              deletedAt,
            );
          }
          break;
      }
    }
  }

  Future<void> _deleteCloudIfNotNewer(
    SupabaseClient client,
    String table,
    String userId,
    String id,
    String deletedAt,
  ) async {
    await client
        .from(table)
        .delete()
        .eq('user_id', userId)
        .eq('id', id)
        .lte('updated_at', deletedAt);
  }

  void _requireWorkspaceOwner(String userId) {
    final ownerId = _database.getSetting('cloud_account_id');

    if (ownerId == null || ownerId.isEmpty) {
      _database.setSetting('cloud_account_id', userId);
      return;
    }

    if (ownerId != userId) {
      throw StateError(
        'Este espacio local está vinculado a otra cuenta. '
        'Orbitask bloqueó la sincronización para evitar mezclar datos.',
      );
    }
  }

  SupabaseClient _requireClient() {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase no está configurado.');
    }
    return client;
  }

  User _requireUser(SupabaseClient client) {
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('No hay una sesión iniciada.');
    }
    return user;
  }

  int _millis(Object? value) {
    if (value is DateTime) return value.millisecondsSinceEpoch;
    if (value is String) {
      return DateTime.parse(value).millisecondsSinceEpoch;
    }
    throw FormatException('Fecha de Supabase inválida: $value');
  }

  int? _nullableMillis(Object? value) {
    if (value == null) return null;
    return _millis(value);
  }

  String _iso(DateTime value) => value.toUtc().toIso8601String();
}
