import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'database/local_database.dart';
import 'repositories/task_repository.dart';
import 'screens/home/home_screen.dart';

class TodoApp extends StatefulWidget {
  const TodoApp({
    super.key,
    required this.database,
    required this.taskRepository,
  });

  final LocalDatabase database;
  final TaskRepository taskRepository;

  @override
  State<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends State<TodoApp> {
  @override
  void dispose() {
    widget.database.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mi TO-DO',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: HomeScreen(taskRepository: widget.taskRepository),
    );
  }
}
