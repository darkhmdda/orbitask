import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'database/local_database.dart';
import 'repositories/todo_repository.dart';
import 'screens/auth/auth_gate.dart';
import 'screens/home/home_screen.dart';
import 'services/auth_service.dart';
import 'services/cloud_sync_service.dart';
import 'services/notification_service.dart';
import 'services/profile_service.dart';

class OrbitaskApp extends StatefulWidget {
  const OrbitaskApp({
    super.key,
    required this.database,
    required this.repository,
    required this.notificationService,
    required this.authService,
    required this.cloudSyncService,
    required this.profileService,
  });

  final LocalDatabase database;
  final TodoRepository repository;
  final NotificationService notificationService;
  final AuthService authService;
  final CloudSyncService cloudSyncService;
  final ProfileService profileService;

  @override
  State<OrbitaskApp> createState() => _OrbitaskAppState();
}

class _OrbitaskAppState extends State<OrbitaskApp> {
  late String _themeId;

  @override
  void initState() {
    super.initState();
    _themeId = AppTheme.normalizeThemeId(
      widget.database.getSetting('theme_id'),
    );
  }

  void _changeTheme(String themeId) {
    final normalized = AppTheme.normalizeThemeId(themeId);
    if (normalized == _themeId) return;

    widget.database.setSetting('theme_id', normalized);
    widget.database.setSetting(
      'theme_updated_at',
      DateTime.now().millisecondsSinceEpoch.toString(),
    );
    setState(() => _themeId = normalized);
  }

  void _applyCloudTheme(String themeId) {
    final normalized = AppTheme.normalizeThemeId(themeId);
    if (normalized == _themeId) return;

    setState(() => _themeId = normalized);
  }

  @override
  void dispose() {
    widget.notificationService.dispose();
    widget.database.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final home = HomeScreen(
      repository: widget.repository,
      notificationService: widget.notificationService,
      authService: widget.authService,
      cloudSyncService: widget.cloudSyncService,
      profileService: widget.profileService,
      themeId: _themeId,
      onThemeChanged: _changeTheme,
      onCloudThemeChanged: _applyCloudTheme,
    );

    return MaterialApp(
      title: 'Orbitask',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.forPreset(_themeId),
      home: widget.authService.isConfigured
          ? AuthGate(
              authService: widget.authService,
              database: widget.database,
              signedInChild: home,
            )
          : home,
    );
  }
}
