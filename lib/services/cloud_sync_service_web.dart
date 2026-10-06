import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/local_database_web.dart';
import '../repositories/todo_repository_web.dart';

class CloudUploadResult {
  const CloudUploadResult({
    required this.lists,
    required this.tasks,
    required this.subtasks,
    required this.reminders,
    required this.attachments,
  });

  final int lists;
  final int tasks;
  final int subtasks;
  final int reminders;
  final int attachments;

  int get total => lists + tasks + subtasks + reminders + attachments;
}

class CloudSyncResult {
  const CloudSyncResult({
    required this.remoteLists,
    required this.remoteTasks,
    required this.remoteSubtasks,
    required this.remoteReminders,
    required this.remoteAttachments,
    required this.remoteDeletions,
    required this.cleanedDeletions,
    required this.themeId,
    required this.uploaded,
  });

  final int remoteLists;
  final int remoteTasks;
  final int remoteSubtasks;
  final int remoteReminders;
  final int remoteAttachments;
  final int remoteDeletions;
  final int cleanedDeletions;
  final String themeId;
  final CloudUploadResult uploaded;

  int get remoteTotal =>
      remoteLists +
      remoteTasks +
      remoteSubtasks +
      remoteReminders +
      remoteAttachments +
      remoteDeletions;
}

class CloudSyncService {
  static const Duration deletionRetention = Duration(days: 365);
  static const Duration deletionCleanupInterval = Duration(days: 1);

  CloudSyncService({
    required SupabaseClient? client,
    required TodoRepository repository,
    required LocalDatabase database,
  }) : this._internal(
          client,
          repository,
          database,
        );

  CloudSyncService._internal(
    this._client,
    this._repository,
    this._database,
  );

  final SupabaseClient? _client;
  final TodoRepository _repository;
  final LocalDatabase _database;

  bool get isConfigured => _client != null;

  DateTime? get lastSuccessfulSyncAt {
    final raw = _database.getSetting('last_cloud_sync_at');
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toLocal();
  }

  DateTime? get lastSuccessfulUploadAt {
    final raw = _database.getSetting('last_cloud_upload_at');
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toLocal();
  }

  RealtimeChannel? subscribeToRemoteChanges(void Function() onChange) {
    final client = _client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return null;

    final channel = client.channel('orbitask:${user.id}:changes');
    const tables = <String>[
      'user_preferences',
      'task_lists',
      'tasks',
      'subtasks',
      'reminders',
      'task_attachments',
      'sync_deletions',
    ];

    for (final table in tables) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: user.id,
        ),
        callback: (_) => onChange(),
      );
    }

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
    final remoteAttachments =
        await client.from('task_attachments').select().eq('user_id', user.id);

    _mergeRemoteSnapshot(
      lists: remoteLists,
      tasks: remoteTasks,
      subtasks: remoteSubtasks,
      reminders: remoteReminders,
    );
    await _mergeRemoteAttachments(client, remoteAttachments);

    _applyLocalDeletionJournal();

    final uploaded = await uploadLocalSnapshot();
    await _uploadDeletionJournal(client, user.id);
    await _applyDeletionJournalToCloud(client, user.id);

    final cleanedDeletions = await _cleanupOldDeletionJournal(
      client,
      user.id,
    );

    _database.setSetting(
      'last_cloud_sync_at',
      DateTime.now().toUtc().toIso8601String(),
    );

    return CloudSyncResult(
      remoteLists: remoteLists.length,
      remoteTasks: remoteTasks.length,
      remoteSubtasks: remoteSubtasks.length,
      remoteReminders: remoteReminders.length,
      remoteAttachments: remoteAttachments.length,
      remoteDeletions: remoteDeletions.length,
      cleanedDeletions: cleanedDeletions,
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
    final attachments = await _repository.getAllAttachments();

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
                'trashed_at':
                    task.trashedAt == null ? null : _iso(task.trashedAt!),
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

    if (attachments.isNotEmpty) {
      final remoteAttachmentRows = await client
          .from('task_attachments')
          .select('id, updated_at')
          .eq('user_id', userId);
      final remoteUpdatedById = <String, int>{
        for (final row in remoteAttachmentRows)
          row['id']! as String: _millis(row['updated_at']),
      };

      final rows = <Map<String, dynamic>>[];
      for (final attachment in attachments) {
        final remoteUpdated = remoteUpdatedById[attachment.id];
        if (remoteUpdated != null &&
            remoteUpdated >= attachment.updatedAt.millisecondsSinceEpoch) {
          continue;
        }

        final safeName = attachment.name.replaceAll(
          RegExp(r'[^A-Za-z0-9._-]+'),
          '_',
        );
        final path =
            '$userId/${attachment.taskId}/${attachment.id}_$safeName';

        await client.storage.from('task-attachments').uploadBinary(
          path,
          attachment.data,
          fileOptions: FileOptions(
            upsert: true,
            contentType: attachment.mimeType,
          ),
        );

        rows.add(<String, dynamic>{
          'user_id': userId,
          'id': attachment.id,
          'task_id': attachment.taskId,
          'name': attachment.name,
          'mime_type': attachment.mimeType,
          'size_bytes': attachment.sizeBytes,
          'storage_path': path,
          'created_at': _iso(attachment.createdAt),
          'updated_at': _iso(attachment.updatedAt),
        });
      }

      if (rows.isNotEmpty) {
        await client.from('task_attachments').upsert(
          rows,
          onConflict: 'user_id,id',
        );
      }
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
      attachments: attachments.length,
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
        _database.setSetting('theme_updated_at', localUpdatedAt.toString());
      }
    }

    if (localUpdatedAt == 0) {
      localUpdatedAt = DateTime.now().millisecondsSinceEpoch;
      _database.setSetting('theme_updated_at', localUpdatedAt.toString());
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
    _mergeCollection(
      key: 'task_lists',
      remote: lists,
      convert: (row) => <String, dynamic>{
        'id': row['id'],
        'name': row['name'],
        'icon': (row['icon'] as String?) ?? 'list',
        'is_system': (row['is_system'] as bool?) ?? false,
        'created_at': _millis(row['created_at']),
        'updated_at': _millis(row['updated_at']),
      },
    );

    _mergeCollection(
      key: 'tasks',
      remote: tasks,
      convert: (row) => <String, dynamic>{
        'id': row['id'],
        'title': row['title'],
        'description': (row['description'] as String?) ?? '',
        'priority': (row['priority'] as num?)?.toInt() ?? 0,
        'due_date': _nullableMillis(row['due_date']),
        'completed': (row['completed'] as bool?) ?? false,
        'list_id': (row['list_id'] as String?) ?? 'inbox',
        'trashed_at': _nullableMillis(row['trashed_at']),
        'created_at': _millis(row['created_at']),
        'updated_at': _millis(row['updated_at']),
      },
    );

    _mergeCollection(
      key: 'subtasks',
      remote: subtasks,
      convert: (row) => <String, dynamic>{
        'id': row['id'],
        'task_id': row['task_id'],
        'title': row['title'],
        'completed': (row['completed'] as bool?) ?? false,
        'position': (row['position'] as num?)?.toInt() ?? 0,
        'created_at': _millis(row['created_at']),
        'updated_at': _millis(row['updated_at']),
      },
    );

    _mergeCollection(
      key: 'reminders',
      remote: reminders,
      convert: (row) => <String, dynamic>{
        'id': row['id'],
        'task_id': row['task_id'],
        'scheduled_at': _millis(row['scheduled_at']),
        'offset_minutes': (row['offset_minutes'] as num?)?.toInt(),
        'enabled': (row['enabled'] as bool?) ?? true,
        'created_at': _millis(row['created_at']),
        'updated_at': _millis(row['updated_at']),
      },
    );
  }

  void _mergeCollection({
    required String key,
    required List<Map<String, dynamic>> remote,
    required Map<String, dynamic> Function(Map<String, dynamic>) convert,
  }) {
    final local = _database.readCollection(key);
    for (final remoteRow in remote) {
      final converted = convert(remoteRow);
      final id = converted['id'] as String;
      final index = local.indexWhere((item) => item['id'] == id);
      if (index == -1) {
        local.add(converted);
        continue;
      }

      final localUpdated = (local[index]['updated_at'] as num?)?.toInt() ?? 0;
      final remoteUpdated = (converted['updated_at'] as num?)?.toInt() ?? 0;
      if (remoteUpdated > localUpdated) {
        local[index] = converted;
      }
    }
    _database.writeCollection(key, local);
  }

  Future<void> _mergeRemoteAttachments(
    SupabaseClient client,
    List<Map<String, dynamic>> remote,
  ) async {
    final local = _database.readCollection('task_attachments');

    for (final row in remote) {
      final id = row['id']! as String;
      final updatedAt = _millis(row['updated_at']);
      final index = local.indexWhere((item) => item['id'] == id);
      final localUpdated = index == -1
          ? -1
          : ((local[index]['updated_at'] as num?)?.toInt() ?? 0);
      final localData = index == -1
          ? ''
          : ((local[index]['data_base64'] as String?) ?? '');

      // Web intentionally does not persist attachment bytes in localStorage.
      // After a reload, metadata may be current while bytes are absent, so
      // fetch the remote object again whenever the local payload is empty.
      if (localUpdated >= updatedAt && localData.isNotEmpty) continue;

      final path = row['storage_path']! as String;
      final data = await client.storage.from('task-attachments').download(path);
      final converted = <String, dynamic>{
        'id': id,
        'task_id': row['task_id']! as String,
        'name': row['name']! as String,
        'mime_type': row['mime_type']! as String,
        'size_bytes': (row['size_bytes'] as num).toInt(),
        'data_base64': base64Encode(data),
        'remote_path': path,
        'created_at': _millis(row['created_at']),
        'updated_at': updatedAt,
      };

      if (index == -1) {
        local.add(converted);
      } else {
        local[index] = converted;
      }
    }

    _database.writeCollection('task_attachments', local);
  }

  void _mergeRemoteDeletions(List<Map<String, dynamic>> remote) {
    final local = _database.readCollection('sync_deletions');

    for (final row in remote) {
      final converted = <String, dynamic>{
        'entity_type': row['entity_type'],
        'entity_id': row['entity_id'],
        'deleted_at': _millis(row['deleted_at']),
      };

      final index = local.indexWhere(
        (item) =>
            item['entity_type'] == converted['entity_type'] &&
            item['entity_id'] == converted['entity_id'],
      );

      if (index == -1) {
        local.add(converted);
      } else if ((converted['deleted_at'] as int) >
          ((local[index]['deleted_at'] as num?)?.toInt() ?? 0)) {
        local[index] = converted;
      }
    }

    _database.writeCollection('sync_deletions', local);
  }

  void _applyLocalDeletionJournal() {
    final rows = _database.readCollection('sync_deletions')
      ..sort(
        (a, b) => ((a['deleted_at'] as num?)?.toInt() ?? 0)
            .compareTo((b['deleted_at'] as num?)?.toInt() ?? 0),
      );

    for (final row in rows) {
      final type = row['entity_type'] as String;
      final id = row['entity_id'] as String;
      final deletedAt = (row['deleted_at'] as num).toInt();

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
        case 'attachment':
          _deleteLocalIfNotNewer('task_attachments', id, deletedAt);
          break;
        case 'task_list':
          if (id == 'inbox') break;
          final lists = _database.readCollection('task_lists');
          final listIndex = lists.indexWhere((item) => item['id'] == id);
          final canDelete = listIndex == -1 ||
              ((lists[listIndex]['updated_at'] as num?)?.toInt() ?? 0) <=
                  deletedAt;
          if (canDelete) {
            final tasks = _database.readCollection('tasks');
            for (final task in tasks) {
              if (task['list_id'] == id) {
                task['list_id'] = 'inbox';
                task['updated_at'] = deletedAt;
              }
            }
            _database.writeCollection('tasks', tasks);
            _deleteLocalIfNotNewer('task_lists', id, deletedAt);
          }
          break;
      }
    }
  }

  void _deleteLocalIfNotNewer(String key, String id, int deletedAt) {
    final items = _database.readCollection(key);
    items.removeWhere(
      (item) =>
          item['id'] == id &&
          (((item['updated_at'] as num?)?.toInt() ?? 0) <= deletedAt),
    );
    _database.writeCollection(key, items);
  }

  Future<void> _uploadDeletionJournal(
    SupabaseClient client,
    String userId,
  ) async {
    final rows = _database.readCollection('sync_deletions');
    if (rows.isEmpty) return;

    await client.from('sync_deletions').upsert(
      rows
          .map(
            (row) => <String, dynamic>{
              'user_id': userId,
              'entity_type': row['entity_type'] as String,
              'entity_id': row['entity_id'] as String,
              'deleted_at': DateTime.fromMillisecondsSinceEpoch(
                (row['deleted_at'] as num).toInt(),
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
    final rows = _database.readCollection('sync_deletions')
      ..sort(
        (a, b) => ((a['deleted_at'] as num?)?.toInt() ?? 0)
            .compareTo((b['deleted_at'] as num?)?.toInt() ?? 0),
      );

    for (final row in rows) {
      final type = row['entity_type'] as String;
      final id = row['entity_id'] as String;
      final deletedAt = DateTime.fromMillisecondsSinceEpoch(
        (row['deleted_at'] as num).toInt(),
        isUtc: true,
      ).toIso8601String();

      if (type == 'attachment') {
        await _deleteAttachmentCloudIfNotNewer(
          client,
          userId,
          id,
          deletedAt,
        );
        continue;
      }

      final table = switch (type) {
        'reminder' => 'reminders',
        'subtask' => 'subtasks',
        'task' => 'tasks',
        'task_list' => 'task_lists',
        _ => null,
      };

      if (table == null || (type == 'task_list' && id == 'inbox')) continue;

      await _deleteCloudIfNotNewer(
        client,
        table,
        userId,
        id,
        deletedAt,
      );
    }
  }

  Future<int> _cleanupOldDeletionJournal(
    SupabaseClient client,
    String userId,
  ) async {
    final now = DateTime.now().toUtc();
    final lastCleanupRaw =
        _database.getSetting('last_tombstone_cleanup_at');
    final lastCleanup = lastCleanupRaw == null
        ? null
        : DateTime.tryParse(lastCleanupRaw)?.toUtc();

    if (lastCleanup != null &&
        now.difference(lastCleanup) < deletionCleanupInterval) {
      return 0;
    }

    final cutoff = now.subtract(deletionRetention);
    final cutoffMillis = cutoff.millisecondsSinceEpoch;
    final cutoffIso = cutoff.toIso8601String();

    final rows = _database.readCollection('sync_deletions');
    final localCount = rows
        .where(
          (row) =>
              ((row['deleted_at'] as num?)?.toInt() ?? 0) < cutoffMillis,
        )
        .length;

    await client
        .from('sync_deletions')
        .delete()
        .eq('user_id', userId)
        .lt('deleted_at', cutoffIso);

    rows.removeWhere(
      (row) => ((row['deleted_at'] as num?)?.toInt() ?? 0) < cutoffMillis,
    );
    _database.writeCollection('sync_deletions', rows);

    _database.setSetting(
      'last_tombstone_cleanup_at',
      now.toIso8601String(),
    );

    return localCount;
  }

  Future<void> _deleteAttachmentCloudIfNotNewer(
    SupabaseClient client,
    String userId,
    String id,
    String deletedAt,
  ) async {
    final rows = await client
        .from('task_attachments')
        .select('storage_path, updated_at')
        .eq('user_id', userId)
        .eq('id', id)
        .limit(1);

    if (rows.isEmpty) return;

    final row = rows.first;
    final remoteUpdatedAt = _millis(row['updated_at']);
    final deletionMillis = _millis(deletedAt);
    if (remoteUpdatedAt > deletionMillis) return;

    final path = row['storage_path'] as String?;
    await client
        .from('task_attachments')
        .delete()
        .eq('user_id', userId)
        .eq('id', id)
        .lte('updated_at', deletedAt);

    if (path != null && path.isNotEmpty) {
      await client.storage.from('task-attachments').remove([path]);
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
