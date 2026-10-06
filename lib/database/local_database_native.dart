import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

class LocalDatabase {
  LocalDatabase._(this._database, this.path);

  final Database _database;
  final String path;

  Database get raw => _database;

  static LocalDatabase openInMemoryForTesting() {
    final database = sqlite3.openInMemory();
    database.execute('PRAGMA foreign_keys = ON;');
    _createAndMigrate(database);
    return LocalDatabase._(database, ':memory:');
  }

  static Future<LocalDatabase> open() async {
    final directory = await getApplicationSupportDirectory();
    await directory.create(recursive: true);

    final databasePath =
        '${directory.path}${Platform.pathSeparator}orbitask.sqlite';

    await _copyLegacyDatabaseIfNeeded(directory, databasePath);

    final database = sqlite3.open(databasePath);

    database.execute('PRAGMA foreign_keys = ON;');
    database.execute('PRAGMA journal_mode = WAL;');

    _createAndMigrate(database);

    return LocalDatabase._(database, databasePath);
  }

  static Future<void> _copyLegacyDatabaseIfNeeded(
    Directory directory,
    String databasePath,
  ) async {
    final destination = File(databasePath);
    if (await destination.exists()) return;

    final separator = Platform.pathSeparator;
    final candidates = <String>{
      '${directory.path}${separator}todo_app.sqlite',
      '${directory.parent.path}${separator}todo_app${separator}todo_app.sqlite',
      '${directory.parent.path}${separator}com.example.todo_app${separator}todo_app.sqlite',
    };

    if (Platform.isLinux) {
      final home = Platform.environment['HOME'];
      if (home != null && home.isNotEmpty) {
        candidates.addAll([
          '$home/.local/share/todo_app.sqlite',
          '$home/.local/share/todo_app/todo_app.sqlite',
          '$home/.local/share/com.example.todo_app/todo_app.sqlite',
        ]);
      }
    }

    for (final legacyPath in candidates) {
      if (legacyPath == databasePath) continue;

      final legacy = File(legacyPath);
      if (!await legacy.exists()) continue;

      await legacy.copy(databasePath);

      final legacyWal = File('$legacyPath-wal');
      if (await legacyWal.exists()) {
        await legacyWal.copy('$databasePath-wal');
      }

      return;
    }
  }

  static void _createAndMigrate(Database database) {
    database.execute('BEGIN IMMEDIATE;');

    try {
      database.execute('''
        CREATE TABLE IF NOT EXISTS task_lists (
          id TEXT PRIMARY KEY NOT NULL,
          name TEXT NOT NULL,
          icon TEXT NOT NULL DEFAULT '📋',
          is_system INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        );
      ''');

      database.execute('''
        CREATE TABLE IF NOT EXISTS tasks (
          id TEXT PRIMARY KEY NOT NULL,
          title TEXT NOT NULL,
          description TEXT NOT NULL DEFAULT '',
          priority INTEGER NOT NULL DEFAULT 0,
          due_date INTEGER,
          completed INTEGER NOT NULL DEFAULT 0,
          list_id TEXT NOT NULL DEFAULT 'inbox',
          trashed_at INTEGER,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        );
      ''');

      final taskColumns = database
          .select('PRAGMA table_info(tasks);')
          .map((row) => row['name'] as String)
          .toSet();

      if (!taskColumns.contains('list_id')) {
        database.execute(
          "ALTER TABLE tasks ADD COLUMN list_id TEXT NOT NULL DEFAULT 'inbox';",
        );
      }

      if (!taskColumns.contains('trashed_at')) {
        database.execute(
          'ALTER TABLE tasks ADD COLUMN trashed_at INTEGER;',
        );
      }

      database.execute('''
        CREATE TABLE IF NOT EXISTS subtasks (
          id TEXT PRIMARY KEY NOT NULL,
          task_id TEXT NOT NULL,
          title TEXT NOT NULL,
          completed INTEGER NOT NULL DEFAULT 0,
          position INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE
        );
      ''');

      database.execute('''
        CREATE TABLE IF NOT EXISTS reminders (
          id TEXT PRIMARY KEY NOT NULL,
          task_id TEXT NOT NULL,
          scheduled_at INTEGER NOT NULL,
          offset_minutes INTEGER,
          enabled INTEGER NOT NULL DEFAULT 1,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE
        );
      ''');

      database.execute('''
        CREATE TABLE IF NOT EXISTS task_attachments (
          id TEXT PRIMARY KEY NOT NULL,
          task_id TEXT NOT NULL,
          name TEXT NOT NULL,
          mime_type TEXT NOT NULL,
          size_bytes INTEGER NOT NULL,
          data BLOB NOT NULL,
          remote_path TEXT,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE
        );
      ''');

      database.execute('''
        CREATE TABLE IF NOT EXISTS app_settings (
          key TEXT PRIMARY KEY NOT NULL,
          value TEXT NOT NULL
        );
      ''');

      database.execute('''
        CREATE TABLE IF NOT EXISTS sync_deletions (
          entity_type TEXT NOT NULL,
          entity_id TEXT NOT NULL,
          deleted_at INTEGER NOT NULL,
          PRIMARY KEY (entity_type, entity_id)
        );
      ''');

      database.execute(r'''
        UPDATE task_lists
        SET icon = CASE icon
          WHEN '📋' THEN 'list'
          WHEN '📥' THEN 'inbox'
          WHEN '📚' THEN 'school'
          WHEN '🏠' THEN 'home'
          WHEN '💻' THEN 'computer'
          WHEN '🛒' THEN 'shopping'
          WHEN '💡' THEN 'idea'
          WHEN '🎯' THEN 'target'
          WHEN '⭐' THEN 'star'
          WHEN '🧰' THEN 'tools'
          ELSE icon
        END;
      ''');

      final now = DateTime.now().millisecondsSinceEpoch;
      final listCountRow = database.select(
        'SELECT COUNT(*) AS total FROM task_lists;',
      ).first;
      final listCount = (listCountRow['total'] as int?) ?? 0;

      final seedLists = <List<Object?>>[
        ['inbox', 'Bandeja de entrada', 'inbox', 1, now, now],
      ];

      if (listCount == 0) {
        seedLists.addAll([
          ['university', 'Universidad', 'school', 0, now, now],
          ['personal', 'Personal', 'home', 0, now, now],
          ['projects', 'Proyectos', 'computer', 0, now, now],
          ['shopping', 'Compras', 'shopping', 0, now, now],
        ]);
      }

      final seedStatement = database.prepare('''
        INSERT OR IGNORE INTO task_lists (
          id,
          name,
          icon,
          is_system,
          created_at,
          updated_at
        ) VALUES (?, ?, ?, ?, ?, ?);
      ''');

      try {
        for (final values in seedLists) {
          seedStatement.execute(values);
        }
      } finally {
        seedStatement.close();
      }

      database.execute('''
        UPDATE tasks
        SET list_id = 'inbox'
        WHERE list_id IS NULL OR TRIM(list_id) = '';
      ''');

      database.execute('''
        CREATE INDEX IF NOT EXISTS idx_tasks_due_date
        ON tasks(due_date);
      ''');

      database.execute('''
        CREATE INDEX IF NOT EXISTS idx_tasks_completed
        ON tasks(completed);
      ''');

      database.execute('''
        CREATE INDEX IF NOT EXISTS idx_tasks_list_id
        ON tasks(list_id);
      ''');

      database.execute('''
        CREATE INDEX IF NOT EXISTS idx_tasks_trashed_at
        ON tasks(trashed_at);
      ''');

      database.execute('''
        CREATE INDEX IF NOT EXISTS idx_subtasks_task_id
        ON subtasks(task_id);
      ''');

      database.execute('''
        CREATE INDEX IF NOT EXISTS idx_subtasks_position
        ON subtasks(task_id, position);
      ''');

      database.execute('''
        CREATE INDEX IF NOT EXISTS idx_reminders_task_id
        ON reminders(task_id);
      ''');

      database.execute('''
        CREATE INDEX IF NOT EXISTS idx_reminders_scheduled_at
        ON reminders(scheduled_at);
      ''');

      database.execute('''
        CREATE INDEX IF NOT EXISTS idx_task_attachments_task_id
        ON task_attachments(task_id);
      ''');


      database.execute('''
        CREATE INDEX IF NOT EXISTS idx_sync_deletions_deleted_at
        ON sync_deletions(deleted_at);
      ''');

      database.execute('COMMIT;');
    } catch (_) {
      database.execute('ROLLBACK;');
      rethrow;
    }
  }

  String? getSetting(String key) {
    final rows = _database.select(
      'SELECT value FROM app_settings WHERE key = ? LIMIT 1;',
      [key],
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  void setSetting(String key, String value) {
    final statement = _database.prepare('''
      INSERT INTO app_settings (key, value)
      VALUES (?, ?)
      ON CONFLICT(key) DO UPDATE SET value = excluded.value;
    ''');

    try {
      statement.execute([key, value]);
    } finally {
      statement.close();
    }
  }

  void close() {
    _database.close();
  }
}
