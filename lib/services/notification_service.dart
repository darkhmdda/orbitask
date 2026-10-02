import 'dart:async';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

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
  NotificationService();

  static const _windowsGuid = '9A4B6A3E-487B-4F47-8E1A-472AF853621E';
  static const _windowsAppId = 'darkhmdda.Orbitask';
  static const _androidChannelId = 'orbitask_reminders';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final Map<int, Timer> _fallbackTimers = {};

  bool _initialized = false;

  bool get initialized => _initialized;

  Future<void> initialize() async {
    tzdata.initializeTimeZones();

    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (_) {
      // timezone defaults to UTC if the platform timezone cannot be resolved.
      // Linux background scheduling uses the OS local clock directly.
    }

    final settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      linux: LinuxInitializationSettings(
        defaultActionName: 'Abrir Orbitask',
      ),
      windows: WindowsInitializationSettings(
        appName: 'Orbitask',
        appUserModelId: _windowsAppId,
        guid: _windowsGuid,
      ),
    );

    try {
      await _plugin.initialize(
        settings: settings,
        onDidReceiveNotificationResponse: (_) {},
      );
      _initialized = true;
    } catch (_) {
      _initialized = false;
    }
  }

  Future<void> requestPermissions() async {
    if (!_initialized) return;

    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
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

    if (Platform.isLinux) {
      final linuxResult = await _scheduleLinuxBackground(
        task: task,
        reminder: reminder,
      );
      if (linuxResult) {
        return const ReminderScheduleResult(
          scheduled: true,
          survivesAppExit: true,
        );
      }

      _scheduleFallbackTimer(task: task, reminder: reminder, delay: delay);
      return const ReminderScheduleResult(
        scheduled: true,
        survivesAppExit: false,
        warning:
            'Linux no pudo crear un temporizador del sistema; el aviso funcionará mientras Orbitask permanezca abierto.',
      );
    }

    if (!_initialized) {
      return const ReminderScheduleResult(
        scheduled: false,
        survivesAppExit: false,
        warning: 'El servicio de notificaciones no pudo inicializarse.',
      );
    }

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _androidChannelId,
        'Recordatorios de Orbitask',
        channelDescription: 'Avisos programados de tareas de Orbitask',
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
      ),
      windows: WindowsNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      id: notificationId(reminder.id),
      title: 'Orbitask',
      body: 'Recordatorio: ${task.title}',
      scheduledDate: tz.TZDateTime.from(reminder.scheduledAt, tz.local),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'task:${task.id}',
    );

    return const ReminderScheduleResult(
      scheduled: true,
      survivesAppExit: true,
    );
  }

  Future<void> cancelReminder(String reminderId) async {
    final id = notificationId(reminderId);
    _fallbackTimers.remove(id)?.cancel();

    if (Platform.isLinux) {
      await _cancelLinuxBackground(id);
      return;
    }

    if (_initialized) {
      try {
        await _plugin.cancel(id: id);
      } catch (_) {}
    }
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

  Future<void> showNow({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) return;

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _androidChannelId,
        'Recordatorios de Orbitask',
        channelDescription: 'Avisos programados de tareas de Orbitask',
        importance: Importance.high,
        priority: Priority.high,
      ),
      linux: LinuxNotificationDetails(
        urgency: LinuxNotificationUrgency.critical,
      ),
      windows: WindowsNotificationDetails(),
    );

    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(2147483647),
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  void dispose() {
    for (final timer in _fallbackTimers.values) {
      timer.cancel();
    }
    _fallbackTimers.clear();
  }

  int notificationId(String reminderId) {
    var hash = 0x811c9dc5;
    for (final codeUnit in reminderId.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash == 0 ? 1 : hash;
  }

  Future<bool> _scheduleLinuxBackground({
    required Task task,
    required Reminder reminder,
  }) async {
    final systemdRun = await _findCommand('systemd-run');
    final notifySend = await _findCommand('notify-send');
    if (systemdRun == null || notifySend == null) return false;

    final id = notificationId(reminder.id);
    final unit = _linuxUnit(id);
    await _cancelLinuxBackground(id);

    final date = reminder.scheduledAt;
    final calendar =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}:'
        '${date.second.toString().padLeft(2, '0')}';

    try {
      final result = await Process.run(
        systemdRun,
        [
          '--user',
          '--quiet',
          '--collect',
          '--unit=$unit',
          '--on-calendar=$calendar',
          '--timer-property=AccuracySec=1s',
          notifySend,
          '--app-name=Orbitask',
          '--urgency=critical',
          '--icon=appointment-soon',
          'Orbitask',
          'Recordatorio: ${task.title}',
        ],
      );

      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  Future<void> _cancelLinuxBackground(int notificationId) async {
    final systemctl = await _findCommand('systemctl');
    if (systemctl == null) return;

    final unit = _linuxUnit(notificationId);
    try {
      await Process.run(
        systemctl,
        ['--user', 'stop', '$unit.timer', '$unit.service'],
      );
      await Process.run(
        systemctl,
        ['--user', 'reset-failed', '$unit.timer', '$unit.service'],
      );
    } catch (_) {}
  }

  void _scheduleFallbackTimer({
    required Task task,
    required Reminder reminder,
    required Duration delay,
  }) {
    final id = notificationId(reminder.id);
    _fallbackTimers[id] = Timer(delay, () async {
      _fallbackTimers.remove(id);
      await showNow(
        title: 'Orbitask',
        body: 'Recordatorio: ${task.title}',
        payload: 'task:${task.id}',
      );
    });
  }

  Future<String?> _findCommand(String command) async {
    try {
      final result = await Process.run('which', [command]);
      if (result.exitCode != 0) return null;
      final path = result.stdout.toString().trim();
      return path.isEmpty ? null : path;
    } catch (_) {
      return null;
    }
  }

  String _linuxUnit(int notificationId) =>
      'orbitask-reminder-$notificationId';
}
