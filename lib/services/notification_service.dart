import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/schedule.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Initialize timezone data
    tz_data.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    await _requestPermissions();
  }

  static Future<void> _requestPermissions() async {
    // Request notification permission
    final notificationStatus = await Permission.notification.request();
    print('Notification permission status: $notificationStatus');

    // For Android 13+ (API 33+), request POST_NOTIFICATIONS permission
    if (await Permission.notification.isDenied) {
      print('Notification permission denied. Requesting again...');
      await Permission.notification.request();
    }

    // Request exact alarm permission for Android 12+
    if (await Permission.scheduleExactAlarm.isDenied) {
      print('Schedule exact alarm permission denied. Requesting...');
      await Permission.scheduleExactAlarm.request();
    }

    // Request battery optimization exemption (important for reliable notifications)
    await _requestBatteryOptimizationExemption();

    // Log final permission status
    await _logPermissionStatus();
  }

  static Future<void> _requestBatteryOptimizationExemption() async {
    try {
      // This helps ensure notifications work even when the app is in background
      final status = await Permission.ignoreBatteryOptimizations.request();
      print('Battery optimization exemption status: $status');
    } catch (e) {
      print('Error requesting battery optimization exemption: $e');
    }
  }

  static Future<void> _logPermissionStatus() async {
    final notificationStatus = await Permission.notification.status;
    final alarmStatus = await Permission.scheduleExactAlarm.status;
    final batteryStatus = await Permission.ignoreBatteryOptimizations.status;

    print('=== PERMISSION STATUS ===');
    print('Notifications: $notificationStatus');
    print('Exact Alarms: $alarmStatus');
    print('Battery Optimization: $batteryStatus');
    print('========================');
  }

  static Future<bool> arePermissionsGranted() async {
    final notificationGranted = await Permission.notification.isGranted;
    final alarmGranted = await Permission.scheduleExactAlarm.isGranted;

    return notificationGranted && alarmGranted;
  }

  static Future<void> openSettings() async {
    await openAppSettings();
  }

  static void _onNotificationResponse(NotificationResponse response) {
    // Handle notification tap
  }

  static Future<void> scheduleNotification(Schedule schedule) async {
    final androidDetails = AndroidNotificationDetails(
      'personal_care_channel',
      'Personal Care Notifications',
      channelDescription: 'Notifications for personal care schedules',
      importance: Importance.high,
      priority: Priority.high,
      sound: _getNotificationSound(schedule.notificationTone),
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    // Schedule initial notification
    await _notificationsPlugin.zonedSchedule(
      schedule.id.hashCode,
      schedule.title,
      schedule.description,
      _getScheduledDateTime(schedule.scheduledTime),
      notificationDetails,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    // Schedule recurring notifications based on frequency
    if (schedule.frequency != ScheduleFrequency.once) {
      await _scheduleRecurringNotifications(schedule);
    }
  }

  static Future<void> _scheduleRecurringNotifications(Schedule schedule) async {
    final endDate =
        schedule.endDate ?? DateTime.now().add(const Duration(days: 30));
    final currentDate = DateTime.now();

    DateTime nextDate = schedule.scheduledTime;

    while (nextDate.isBefore(endDate)) {
      if (nextDate.isAfter(currentDate)) {
        final androidDetails = AndroidNotificationDetails(
          'personal_care_channel',
          'Personal Care Notifications',
          channelDescription: 'Notifications for personal care schedules',
          importance: Importance.high,
          priority: Priority.high,
          sound: _getNotificationSound(schedule.notificationTone),
        );

        final notificationDetails = NotificationDetails(
          android: androidDetails,
        );

        await _notificationsPlugin.zonedSchedule(
          '${schedule.id}_${nextDate.millisecondsSinceEpoch}'.hashCode,
          schedule.title,
          schedule.description,
          _getScheduledDateTime(nextDate),
          notificationDetails,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      }

      // Calculate next date based on frequency
      switch (schedule.frequency) {
        case ScheduleFrequency.daily:
          nextDate = nextDate.add(const Duration(days: 1));
          break;
        case ScheduleFrequency.weekly:
          nextDate = nextDate.add(const Duration(days: 7));
          break;
        case ScheduleFrequency.monthly:
          nextDate = DateTime(
            nextDate.year,
            nextDate.month + 1,
            nextDate.day,
            nextDate.hour,
            nextDate.minute,
          );
          break;
        case ScheduleFrequency.once:
          break;
      }
    }
  }

  static RawResourceAndroidNotificationSound? _getNotificationSound(
    NotificationTone tone,
  ) {
    switch (tone) {
      case NotificationTone.gentle:
        return const RawResourceAndroidNotificationSound('gentle_notification');
      case NotificationTone.urgent:
        return const RawResourceAndroidNotificationSound('urgent_notification');
      case NotificationTone.custom:
        return const RawResourceAndroidNotificationSound('custom_notification');
      default:
        return null;
    }
  }

  static tz.TZDateTime _getScheduledDateTime(DateTime dateTime) {
    try {
      // Get the local timezone location
      final location = tz.local;
      return tz.TZDateTime.from(dateTime, location);
    } catch (e) {
      // Fallback to UTC if local timezone is not available
      final location = tz.getLocation('UTC');
      return tz.TZDateTime.from(dateTime, location);
    }
  }

  static Future<void> cancelNotification(String scheduleId) async {
    await _notificationsPlugin.cancel(scheduleId.hashCode);
  }

  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}
