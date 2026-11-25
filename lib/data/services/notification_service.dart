import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../core/constants/app_constants.dart';
import '../models/app_notification.dart';
import '../models/crop_activity.dart';

/// Wraps `flutter_local_notifications` for local scheduling and popups on mobile devices.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse resp) {
        if (kDebugMode) {
          debugPrint('Notification clicked with payload: ${resp.payload}');
        }
      },
    );

    // Request notification permissions for Android 13+ and iOS
    await requestNotificationPermission();

    // Android notification channel setup
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            AppConstants.reminderChannelId,
            AppConstants.reminderChannelName,
            description: AppConstants.reminderChannelDescription,
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
        );

    _initialized = true;
  }

  Future<bool?> requestNotificationPermission() async {
    return _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  /// Displays an immediate popup notification on the device.
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      AppConstants.reminderChannelId,
      AppConstants.reminderChannelName,
      channelDescription: AppConstants.reminderChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    try {
      await _plugin.show(
        id,
        title,
        body,
        const NotificationDetails(android: androidDetails, iOS: iosDetails),
        payload: payload,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Immediate notification display failed: $e');
    }
  }

  /// Schedules a popup notification to trigger at [scheduledDate].
  Future<void> scheduleAppNotification(
    AppNotification notification, {
    bool isBn = false,
  }) async {
    final id = notification.id.hashCode;
    await cancel(id);

    final scheduled = tz.TZDateTime.from(
      notification.scheduledTime,
      tz.local,
    );

    final now = tz.TZDateTime.now(tz.local);
    // If the scheduled time is in the past, or right now (within 5 minutes)
    if (scheduled.isBefore(now)) {
      if (now.difference(scheduled).inMinutes < 5 && !notification.isRead) {
        await showNotification(
          id: id,
          title: isBn ? notification.titleBn : notification.titleEn,
          body: isBn ? notification.bodyBn : notification.bodyEn,
          payload: notification.route,
        );
      }
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      AppConstants.reminderChannelId,
      AppConstants.reminderChannelName,
      channelDescription: AppConstants.reminderChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    try {
      await _plugin.zonedSchedule(
        id,
        isBn ? notification.titleBn : notification.titleEn,
        isBn ? notification.bodyBn : notification.bodyEn,
        scheduled,
        const NotificationDetails(android: androidDetails, iOS: iosDetails),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: notification.route,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('App notification scheduling failed: $e');
    }
  }

  /// Legacy crop activity scheduler
  Future<void> scheduleActivityReminder(CropActivity activity) async {
    final id = activity.id.hashCode;
    await cancel(id);
    final scheduled = tz.TZDateTime.from(activity.scheduledDate, tz.local);

    if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) return;

    const androidDetails = AndroidNotificationDetails(
      AppConstants.reminderChannelId,
      AppConstants.reminderChannelName,
      channelDescription: AppConstants.reminderChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();

    try {
      await _plugin.zonedSchedule(
        id,
        'Reminder: ${activity.title}',
        activity.description.isEmpty
            ? 'Scheduled for Day ${activity.dayFromPlanting}.'
            : activity.description,
        scheduled,
        const NotificationDetails(android: androidDetails, iOS: iosDetails),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Notification scheduling failed: $e');
    }
  }

  Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() async => _plugin.cancelAll();
}
