import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/cloud_config.dart';
import 'database/local_database.dart';
import 'repositories/todo_repository.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SupabaseClient? supabaseClient;
  if (CloudConfig.isConfigured) {
    await Supabase.initialize(
      url: CloudConfig.supabaseUrl,
      publishableKey: CloudConfig.supabasePublishableKey,
    );
    supabaseClient = Supabase.instance.client;
  }

  final database = await LocalDatabase.open();
  final repository = TodoRepository(database);
  final notificationService = NotificationService();
  final authService = AuthService(supabaseClient);

  await notificationService.initialize();

  runApp(
    OrbitaskApp(
      database: database,
      repository: repository,
      notificationService: notificationService,
      authService: authService,
    ),
  );
}
