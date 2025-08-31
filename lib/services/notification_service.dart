import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../core/constants.dart';
import '../database/database.dart';
import '../screens/task_detail_screen.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  late AppDatabase _db;
  late GlobalKey<NavigatorState> _navigatorKey;
  bool _initialized = false;
  late bool testMode;

  Future<void> init({
    required AppDatabase db,
    required GlobalKey<NavigatorState> navigatorKey,
    bool? forceTestMode,
  }) async {
    _db = db;
    _navigatorKey = navigatorKey;
    testMode = forceTestMode ?? 
        const bool.fromEnvironment('NOTIF_TEST_MODE', defaultValue: true);

    await _initializeTimeZones();
    await _initializePlugin();
    await _requestPermissions();

    _initialized = true;
  }

  Future<void> _initializeTimeZones() async {
    tz.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      // Use default location
    }
  }

  Future<void> _initializePlugin() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      macOS: darwinInit,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );
  }

  Future<void> _handleNotificationResponse(NotificationResponse response) async {
    final payload = response.payload;
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
  }

  Future<void> _requestPermissions() async {
    // Android permissions
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
    await androidImpl?.requestExactAlarmsPermission();

    // iOS/macOS permissions
    final iosImpl = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await iosImpl?.requestPermissions(alert: true, badge: true, sound: true);

    final macosImpl = _plugin.resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin>();
    await macosImpl?.requestPermissions(alert: true, badge: true, sound: true);
  }

  NotificationDetails _getNotificationDetails() {
    const android = AndroidNotificationDetails(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      channelDescription: AppConstants.notificationChannelDescription,
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
    return const NotificationDetails(
      android: android,
      iOS: darwin,
      macOS: darwin,
    );
  }

  tz.TZDateTime _computeScheduleTime(Task task) {
    final now = tz.TZDateTime.now(tz.local);

    if (testMode) {
      return now.add(AppConstants.testNotificationDelay);
    }

    return _computeProductionScheduleTime(task, now);
  }

  tz.TZDateTime _computeProductionScheduleTime(Task task, tz.TZDateTime now) {
    final dlLocal = tz.TZDateTime.from(task.deadline, tz.local);
    final midnightOfDeadline = tz.TZDateTime(
      tz.local,
      dlLocal.year,
      dlLocal.month,
      dlLocal.day,
    );

    // Day before at 12:00 PM
    var scheduledTime = midnightOfDeadline
        .subtract(const Duration(days: 1))
        .add(const Duration(hours: 12));

    // If already passed, try fallback
    if (scheduledTime.isBefore(now.add(const Duration(seconds: 5)))) {
      final fallback = now.add(AppConstants.notificationFallbackDelay);
      if (fallback.isBefore(midnightOfDeadline)) {
        scheduledTime = fallback;
      } else {
        return tz.TZDateTime.fromMillisecondsSinceEpoch(tz.local, 0);
      }
    }

    return scheduledTime;
  }

  Future<void> scheduleReminderForTask(Task task) async {
    if (!_initialized || task.completedAt != null) return;

    final when = _computeScheduleTime(task);
    if (when.millisecondsSinceEpoch <= 0) return;

    final (title, body) = _getNotificationContent(task);

    await _plugin.zonedSchedule(
      task.id,
      title,
      body,
      when,
      _getNotificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'task:${task.id}',
    );
  }

  (String title, String body) _getNotificationContent(Task task) {
    final dateText = DateFormat(AppConstants.dateFormat).format(task.deadline);
    final title = '${AppStrings.reminderPrefix}${task.title}';
    final body = testMode
        ? AppStrings.testNotificationBody
        : '${AppStrings.tomorrowDeadline}$dateText';
    
    return (title, body);
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

    for (final task in tasks) {
      if (!pendingIds.contains(task.id)) {
        await scheduleReminderForTask(task);
      }
    }
  }
}