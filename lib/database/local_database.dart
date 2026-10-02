import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

class LocalDatabase {
  LocalDatabase._(this._database, this.path);

  final Database _database;
  final String path;

  Database get raw => _database;

  static Future<LocalDatabase> open() async {
    final directory = await getApplicationSupportDirectory();
    await directory.create(recursive: true);

    final databasePath =
        '${directory.path}${Platform.pathSeparator}todo_app.sqlite';
    final database = sqlite3.open(databasePath);

    database.execute('PRAGMA foreign_keys = ON;');
    database.execute('PRAGMA journal_mode = WAL;');

    _createAndMigrate(database);

    return LocalDatabase._(database, databasePath);
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

      final now = DateTime.now().millisecondsSinceEpoch;
      final listCountRow = database.select(
        'SELECT COUNT(*) AS total FROM task_lists;',
      ).first;
      final listCount = (listCountRow['total'] as int?) ?? 0;

      final seedLists = <List<Object?>>[
        ['inbox', 'Bandeja de entrada', '📥', 1, now, now],
      ];

      if (listCount == 0) {
        seedLists.addAll([
          ['university', 'Universidad', '📚', 0, now, now],
          ['personal', 'Personal', '🏠', 0, now, now],
          ['projects', 'Proyectos', '💻', 0, now, now],
          ['shopping', 'Compras', '🛒', 0, now, now],
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
        CREATE INDEX IF NOT EXISTS idx_subtasks_task_id
        ON subtasks(task_id);
      ''');

      database.execute('''
        CREATE INDEX IF NOT EXISTS idx_subtasks_position
        ON subtasks(task_id, position);
      ''');

      database.execute('COMMIT;');
    } catch (_) {
      database.execute('ROLLBACK;');
      rethrow;
    }
  }

  void close() {
    _database.close();
  }
}
