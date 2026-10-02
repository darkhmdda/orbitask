import '../database/local_database.dart';
import '../models/task.dart';

class TaskRepository {
  TaskRepository(this._database);

  final LocalDatabase _database;

  Future<List<Task>> getAll() async {
    final rows = _database.raw.select('''
      SELECT
        id,
        title,
        description,
        priority,
        due_date,
        completed,
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

  Future<void> create(Task task) async {
    final statement = _database.raw.prepare('''
      INSERT INTO tasks (
        id,
        title,
        description,
        priority,
        due_date,
        completed,
        created_at,
        updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    ''');

    try {
      statement.execute([
        task.id,
        task.title,
        task.description,
        task.priority.index,
        task.dueDate?.millisecondsSinceEpoch,
        task.completed ? 1 : 0,
        task.createdAt.millisecondsSinceEpoch,
        task.updatedAt.millisecondsSinceEpoch,
      ]);
    } finally {
      statement.close();
    }
  }

  Future<void> update(Task task) async {
    final statement = _database.raw.prepare('''
      UPDATE tasks
      SET
        title = ?,
        description = ?,
        priority = ?,
        due_date = ?,
        completed = ?,
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
        task.updatedAt.millisecondsSinceEpoch,
        task.id,
      ]);
    } finally {
      statement.close();
    }
  }

  Future<void> delete(String id) async {
    final statement = _database.raw.prepare('DELETE FROM tasks WHERE id = ?;');

    try {
      statement.execute([id]);
    } finally {
      statement.close();
    }
  }

  Task _taskFromRow(Map<String, Object?> row) {
    final priorityIndex = (row['priority'] as int?) ?? 0;
    final safePriority = priorityIndex >= 0 &&
            priorityIndex < TaskPriority.values.length
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
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row['created_at']! as int,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row['updated_at']! as int,
      ),
    );
  }
}
