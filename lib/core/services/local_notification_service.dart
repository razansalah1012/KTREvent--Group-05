import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';
import 'dart:io';

class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
      },
    );
  }

  Future<void> requestPermissions() async {
    if (kIsWeb) return;
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.requestNotificationsPermission();
      await androidImplementation?.requestExactAlarmsPermission();
    }
  }

  Future<void> scheduleEventReminder({
    required String eventId,
    required String title,
    required DateTime eventDate,
    required String eventTime,
  }) async {
    await requestPermissions();

    final DateTime scheduledDate24h = eventDate.subtract(const Duration(days: 1));

    if (scheduledDate24h.isAfter(DateTime.now())) {
      await _scheduleNotification(
        id: eventId.hashCode,
        title: 'Upcoming Event: $title',
        body: 'Your event starts tomorrow!',
        scheduledDate: scheduledDate24h,
      );
    }

    DateTime startTime = DateTime(eventDate.year, eventDate.month, eventDate.day, 9, 0);
    try {
      if (eventTime.isNotEmpty) {
        final timePart = eventTime.split('-').first.trim();
        final isPM = timePart.toUpperCase().contains('PM');
        final cleanTime = timePart.replaceAll(RegExp(r'[^0-9:]'), '');
        final parts = cleanTime.split(':');
        int hour = int.parse(parts[0]);
        int minute = parts.length > 1 ? int.parse(parts[1]) : 0;
        if (isPM && hour != 12) hour += 12;
        if (!isPM && hour == 12) hour = 0;
        startTime = DateTime(eventDate.year, eventDate.month, eventDate.day, hour, minute);
      }
    } catch (e) {
      debugPrint("Error parsing time: $e");
    }

    final DateTime scheduledDate1h = startTime.subtract(const Duration(hours: 1));
    if (scheduledDate1h.isAfter(DateTime.now())) {
      await _scheduleNotification(
        id: eventId.hashCode + 1,
        title: 'Event Starting Soon: $title',
        body: 'Your event starts in 1 hour!',
        scheduledDate: scheduledDate1h,
      );
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'event_reminders_channel',
          'Event Reminders',
          channelDescription: 'Notifications for upcoming events',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelEventReminder(String eventId) async {
    await flutterLocalNotificationsPlugin.cancel(id: eventId.hashCode);
    await flutterLocalNotificationsPlugin.cancel(id: eventId.hashCode + 1);
  }

  Future<bool> hasReminder(String eventId) async {
    final List<PendingNotificationRequest> pendingNotificationRequests =
        await flutterLocalNotificationsPlugin.pendingNotificationRequests();
    return pendingNotificationRequests.any((notification) => notification.id == eventId.hashCode || notification.id == eventId.hashCode + 1);
  }
}
