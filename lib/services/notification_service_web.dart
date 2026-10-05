import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import '../models/reminder.dart';
import '../models/task.dart';

class ReminderScheduleResult {
  const ReminderScheduleResult({
    required this.scheduled,
    required this.survivesAppExit,
    this.warning,
  });

  final bool scheduled;
  final bool survivesAppExit;
  final String? warning;
}

class NotificationService {
  final Map<int, Timer> _timers = <int, Timer>{};
  bool _initialized = false;

  bool get initialized => _initialized;

  Future<void> initialize() async {
    _initialized = true;
  }

  Future<void> requestPermissions({bool exactAlarms = false}) async {
    if (web.Notification.permission == 'default') {
      await web.Notification.requestPermission().toDart;
    }
  }

  Future<ReminderScheduleResult> scheduleReminder({
    required Task task,
    required Reminder reminder,
  }) async {
    await cancelReminder(reminder.id);

    if (!reminder.enabled || task.completed) {
      return const ReminderScheduleResult(
        scheduled: false,
        survivesAppExit: false,
      );
    }

    final delay = reminder.scheduledAt.difference(DateTime.now());
    if (delay <= Duration.zero) {
      return const ReminderScheduleResult(
        scheduled: false,
        survivesAppExit: false,
        warning: 'El recordatorio ya pasó.',
      );
    }

    await requestPermissions();

    final id = notificationId(reminder.id);
    _timers[id] = Timer(delay, () async {
      _timers.remove(id);
      await showNow(
        title: task.title,
        body: task.description.trim().isEmpty
            ? 'Recordatorio de Orbitask'
            : task.description.trim(),
        payload: task.id,
      );
    });

    final permissionGranted = web.Notification.permission == 'granted';

    return ReminderScheduleResult(
      scheduled: true,
      survivesAppExit: false,
      warning: permissionGranted
          ? 'En Web, la notificación funciona mientras Orbitask permanezca abierto en esta pestaña.'
          : 'Permite las notificaciones del navegador para recibir recordatorios mientras Orbitask esté abierto.',
    );
  }

  Future<void> cancelReminder(String reminderId) async {
    _timers.remove(notificationId(reminderId))?.cancel();
  }

  Future<void> cancelReminders(Iterable<Reminder> reminders) async {
    for (final reminder in reminders) {
      await cancelReminder(reminder.id);
    }
  }

  Future<String?> scheduleTaskReminders({
    required Task task,
    required List<Reminder> reminders,
  }) async {
    String? warning;
    for (final reminder in reminders) {
      final result = await scheduleReminder(task: task, reminder: reminder);
      warning ??= result.warning;
    }
    return warning;
  }

  Future<bool> showNow({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (web.Notification.permission != 'granted') {
      return false;
    }

    try {
      web.Notification(
        'Orbitask · $title',
        web.NotificationOptions(
          body: body,
          icon: 'favicon.png',
          tag: payload ?? 'orbitask-reminder',
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
  }

  int notificationId(String reminderId) {
    var hash = 0x811c9dc5;
    for (final codeUnit in reminderId.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash == 0 ? 1 : hash;
  }
}
