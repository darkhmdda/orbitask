import 'dart:convert';

import 'package:web/web.dart' as web;

class LocalDatabase {
  LocalDatabase._(this._state);

  static const _storageKey = 'orbitask.web.store.v1';

  final Map<String, dynamic> _state;

  String get path => 'browser-local-storage';

  static LocalDatabase openInMemoryForTesting() {
    return LocalDatabase._(_newState());
  }

  static Future<LocalDatabase> open() async {
    Map<String, dynamic> state;
    final raw = web.window.localStorage.getItem(_storageKey);

    if (raw == null || raw.isEmpty) {
      state = _newState();
    } else {
      try {
        final decoded = jsonDecode(raw);
        state = decoded is Map<String, dynamic>
            ? decoded
            : Map<String, dynamic>.from(decoded as Map);
      } catch (_) {
        state = _newState();
      }
    }

    final database = LocalDatabase._(state);
    database._ensureShape();
    database._persist();
    return database;
  }

  String? getSetting(String key) {
    final settings = _settings;
    return settings[key] as String?;
  }

  void setSetting(String key, String value) {
    _settings[key] = value;
    _persist();
  }

  List<Map<String, dynamic>> readCollection(String key) {
    final raw = _state[key];
    if (raw is! List) return <Map<String, dynamic>>[];

    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: true);
  }

  void writeCollection(String key, List<Map<String, dynamic>> items) {
    _state[key] = items;
    _persist();
  }

  void close() {}

  Map<String, dynamic> get _settings {
    final current = _state['settings'];
    if (current is Map<String, dynamic>) return current;

    final settings = current is Map
        ? Map<String, dynamic>.from(current)
        : <String, dynamic>{};
    _state['settings'] = settings;
    return settings;
  }

  void _ensureShape() {
    _state.putIfAbsent('settings', () => <String, dynamic>{});
    _state.putIfAbsent('task_lists', () => <Map<String, dynamic>>[]);
    _state.putIfAbsent('tasks', () => <Map<String, dynamic>>[]);
    _state.putIfAbsent('subtasks', () => <Map<String, dynamic>>[]);
    _state.putIfAbsent('reminders', () => <Map<String, dynamic>>[]);
    _state.putIfAbsent('task_attachments', () => <Map<String, dynamic>>[]);
    _state.putIfAbsent('sync_deletions', () => <Map<String, dynamic>>[]);

    final lists = readCollection('task_lists');
    if (!lists.any((item) => item['id'] == 'inbox')) {
      final now = DateTime.now().millisecondsSinceEpoch;
      lists.insert(0, <String, dynamic>{
        'id': 'inbox',
        'name': 'Bandeja de entrada',
        'icon': 'inbox',
        'is_system': true,
        'created_at': now,
        'updated_at': now,
      });

      if (lists.length == 1) {
        lists.addAll([
          {
            'id': 'university',
            'name': 'Universidad',
            'icon': 'school',
            'is_system': false,
            'created_at': now,
            'updated_at': now,
          },
          {
            'id': 'personal',
            'name': 'Personal',
            'icon': 'home',
            'is_system': false,
            'created_at': now,
            'updated_at': now,
          },
          {
            'id': 'projects',
            'name': 'Proyectos',
            'icon': 'computer',
            'is_system': false,
            'created_at': now,
            'updated_at': now,
          },
          {
            'id': 'shopping',
            'name': 'Compras',
            'icon': 'shopping',
            'is_system': false,
            'created_at': now,
            'updated_at': now,
          },
        ]);
      }

      _state['task_lists'] = lists;
    }
  }

  void _persist() {
    web.window.localStorage.setItem(_storageKey, jsonEncode(_state));
  }

  static Map<String, dynamic> _newState() {
    return <String, dynamic>{
      'settings': <String, dynamic>{},
      'task_lists': <Map<String, dynamic>>[],
      'tasks': <Map<String, dynamic>>[],
      'subtasks': <Map<String, dynamic>>[],
      'reminders': <Map<String, dynamic>>[],
      'task_attachments': <Map<String, dynamic>>[],
      'sync_deletions': <Map<String, dynamic>>[],
    };
  }
}
