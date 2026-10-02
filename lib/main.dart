import 'package:flutter/material.dart';

import 'app.dart';
import 'database/local_database.dart';
import 'repositories/todo_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = await LocalDatabase.open();
  final repository = TodoRepository(database);

  runApp(
    TodoApp(
      database: database,
      repository: repository,
    ),
  );
}
