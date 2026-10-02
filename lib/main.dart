import 'package:flutter/material.dart';

import 'app.dart';
import 'database/local_database.dart';
import 'repositories/task_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = await LocalDatabase.open();
  final taskRepository = TaskRepository(database);

  runApp(
    TodoApp(
      database: database,
      taskRepository: taskRepository,
    ),
  );
}
