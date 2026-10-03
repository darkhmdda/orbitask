import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'database/local_database.dart';
import 'repositories/todo_repository.dart';
import 'screens/home/home_screen.dart';
import 'services/notification_service.dart';

class OrbitaskApp extends StatefulWidget {
  const OrbitaskApp({
    super.key,
    required this.database,
    required this.repository,
    required this.notificationService,
  });

  final LocalDatabase database;
  final TodoRepository repository;
  final NotificationService notificationService;

  @override
  State<OrbitaskApp> createState() => _OrbitaskAppState();
}

class _OrbitaskAppState extends State<OrbitaskApp> {
  @override
  void dispose() {
    widget.notificationService.dispose();
    widget.database.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Orbitask',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: HomeScreen(
        repository: widget.repository,
        notificationService: widget.notificationService,
      ),
    );
  }
}
