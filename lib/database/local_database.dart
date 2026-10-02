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
    database.execute('''
      CREATE TABLE IF NOT EXISTS tasks (
        id TEXT PRIMARY KEY NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        priority INTEGER NOT NULL DEFAULT 0,
        due_date INTEGER,
        completed INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      );
    ''');

    database.execute('''
      CREATE INDEX IF NOT EXISTS idx_tasks_due_date
      ON tasks(due_date);
    ''');

    database.execute('''
      CREATE INDEX IF NOT EXISTS idx_tasks_completed
      ON tasks(completed);
    ''');

    return LocalDatabase._(database, databasePath);
  }

  void close() {
    _database.close();
  }
}
