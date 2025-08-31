import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_task_manager/database/database.dart';
import 'package:flutter_task_manager/screens/task_detail_screen.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  late AppDatabase _db;
  late GlobalKey<NavigatorState> _navigatorKey;

  bool _initialized = false;

    // Test mode: 1 minute after adding vs. production mode 12:00 noon the day before.
  late bool testMode;

  static const String channelId = 'deadline_reminders';
  static const String channelName = 'Deadline reminders';
  static const String channelDescription =
      'Powiadomienia o zbliżających się terminach';

  Future<void> init({
    required AppDatabase db,
    required GlobalKey<NavigatorState> navigatorKey,
    bool? forceTestMode,
  }) async {
    _db = db;
    _navigatorKey = navigatorKey;
    testMode =
        forceTestMode ?? const bool.fromEnvironment('NOTIF_TEST_MODE', defaultValue: true);

    // Time zones (for zonedSchedule).
    tz.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      // Fallback: leave the default location
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    final darwinInit = DarwinInitializationSettings();
    final settings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      macOS: darwinInit,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse r) async {
        final payload = r.payload;
        if (payload != null && payload.startsWith('task:')) {
          final id = int.tryParse(payload.split(':').last);
          if (id != null) {
            final task = await _db.taskDao.getTaskById(id);
            if (task != null) {
              _navigatorKey.currentState?.push(
                MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
              );
            }
          }
        }
      },
    );

    // Android 13+: request for permission to send notifications
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();

    // Android 14+: if you want accurate alarms
    await androidImpl?.requestExactAlarmsPermission();

    // iOS/macOS: permissions
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _plugin
        .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  NotificationDetails _details() {
    const android = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
      ticker: 'deadline',
    );
    const darwin = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
    );
    return const NotificationDetails(android: android, iOS: darwin, macOS: darwin);
  }

  // 12:00 (noon) the day before the deadline; in test mode: +1 min
  tz.TZDateTime _computeScheduleTime(Task task) {
    final now = tz.TZDateTime.now(tz.local);

    if (testMode) {
      return now.add(const Duration(minutes: 1));
    }

    final dlLocal = tz.TZDateTime.from(task.deadline, tz.local);
    final midnightOfDeadline =
        tz.TZDateTime(tz.local, dlLocal.year, dlLocal.month, dlLocal.day);

    // The day before at 12:00 p.m.
    var at = midnightOfDeadline
        .subtract(const Duration(days: 1))
        .add(const Duration(hours: 12));

    // If it has already passed, try 30 minutes from now (if it is still before the deadline).
    if (at.isBefore(now.add(const Duration(seconds: 5)))) {
      final fallback = now.add(const Duration(minutes: 30));
      if (fallback.isBefore(midnightOfDeadline)) {
        at = fallback;
      } else {
        return tz.TZDateTime.fromMillisecondsSinceEpoch(tz.local, 0);
      }
    }
    return at;
  }

  Future<void> scheduleReminderForTask(Task task) async {
    if (!_initialized) return;
    if (task.completedAt != null) return;

    final when = _computeScheduleTime(task);
    if (when.millisecondsSinceEpoch <= 0) return;

    final dateText = DateFormat('dd-MM-yyyy').format(task.deadline);
    final title = 'Przypomnienie: ${task.title}';
    final body = testMode
        ? 'Powiadomienie testowe (1 min po dodaniu).'
        : 'Jutro termin: $dateText';

    await _plugin.zonedSchedule(
      task.id, // we use the task ID as the notification ID
      title,
      body,
      when,
      _details(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'task:${task.id}',
    );
  }

  Future<void> cancelReminder(int taskId) async {
    await _plugin.cancel(taskId);
  }

  Future<void> rescheduleReminderForTask(Task task) async {
    await cancelReminder(task.id);
    await scheduleReminderForTask(task);
  }

  Future<void> scheduleMissingRemindersForIncompleteTasks() async {
    if (!_initialized) return;
    final tasks = await _db.taskDao.getIncompleteTasks();
    final pending = await _plugin.pendingNotificationRequests();
    final pendingIds = pending.map((e) => e.id).toSet();

    for (final t in tasks) {
      if (!pendingIds.contains(t.id)) {
        await scheduleReminderForTask(t);
      }
    }
  }
}