import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'appointment.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // 1. Initialize Timezones
    tz.initializeTimeZones();
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      // Fallback if unable to detect timezone
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    // 2. Initialize Android & iOS Settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle when notification is tapped
      },
    );

    // 3. Request permissions
    // Android:
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
    }

    // iOS:
    final iosImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (iosImplementation != null) {
      await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  Future<void> scheduleReminder(Appointment appt) async {
    try {
      // Cancel any existing reminder for this appointment first
      await cancelReminder(appt.id);

      // If reminder is disabled, do not schedule
      final offsetMinutes = appt.reminderMinutesBefore ?? 1440;
      if (offsetMinutes == -1) {
        return;
      }

      final hour = appt.hour ?? 9; // Default to 9:00 AM if untimed
      final minute = appt.minute ?? 0;

      final apptDateTime = DateTime(
        appt.date.year,
        appt.date.month,
        appt.date.day,
        hour,
        minute,
      );

      final targetDateTime = apptDateTime.subtract(Duration(minutes: offsetMinutes));

      // If reminder time is in the past, do not schedule
      if (targetDateTime.isBefore(DateTime.now())) {
        return;
      }

      final scheduledTZDateTime = tz.TZDateTime.from(targetDateTime, tz.local);

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'appointment_reminders',
        'Appointment Reminders',
        channelDescription: 'Notifications for client appointments',
        importance: Importance.max,
        priority: Priority.high,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
      );

      String titleText = 'Upcoming Appointment: ${appt.clientName}';
      if (offsetMinutes == 1440) {
        titleText = 'Appointment Tomorrow: ${appt.clientName}';
      } else if (offsetMinutes == 2880) {
        titleText = 'Appointment in 2 Days: ${appt.clientName}';
      } else if (offsetMinutes == 60) {
        titleText = 'Appointment in 1 Hour: ${appt.clientName}';
      } else if (offsetMinutes == 120) {
        titleText = 'Appointment in 2 Hours: ${appt.clientName}';
      }

      final recType = appt.recurrenceType ?? RecurrenceType.none;

      if (recType == RecurrenceType.none) {
        await _notificationsPlugin.zonedSchedule(
          appt.id.hashCode,
          titleText,
          'Scheduled at ${_formatTime(appt.hour, appt.minute)} at ${appt.location}',
          scheduledTZDateTime,
          platformDetails,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      } else if (recType == RecurrenceType.weekly) {
        await _notificationsPlugin.zonedSchedule(
          appt.id.hashCode,
          titleText,
          'Weekly client: ${_formatTime(appt.hour, appt.minute)} at ${appt.location}',
          scheduledTZDateTime,
          platformDetails,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      } else if (recType == RecurrenceType.monthly) {
        await _notificationsPlugin.zonedSchedule(
          appt.id.hashCode,
          titleText,
          'Monthly client: ${_formatTime(appt.hour, appt.minute)} at ${appt.location}',
          scheduledTZDateTime,
          platformDetails,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
        );
      }
    } catch (e) {
      // Catch silently or log so it doesn't crash the database save and form close flow
      debugPrint("Notification scheduling error: $e");
    }
  }

  Future<void> cancelReminder(String apptId) async {
    try {
      await _notificationsPlugin.cancel(apptId.hashCode);
    } catch (e) {
      debugPrint("Notification cancellation error: $e");
    }
  }

  String _formatTime(int? hour, int? minute) {
    if (hour == null || minute == null) return 'No Time';
    final period = hour >= 12 ? 'PM' : 'AM';
    var h = hour % 12;
    if (h == 0) h = 12;
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m $period';
  }
}
