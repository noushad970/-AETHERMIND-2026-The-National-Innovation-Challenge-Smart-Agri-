import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../../../data/models/app_notification.dart';
import '../../../../data/models/crop.dart';
import '../../../../data/models/animal.dart';
import '../../../../data/models/weather_data.dart';
import '../../../../data/repositories/local_notification_repository.dart';
import '../../../../data/services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider({
    LocalNotificationRepository? repository,
    NotificationService? service,
  })  : _repository = repository ?? LocalNotificationRepository(),
        _service = service ?? NotificationService.instance;

  final LocalNotificationRepository _repository;
  final NotificationService _service;

  List<AppNotification> _notifications = [];
  bool _loading = false;
  String? _error;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _loading;
  String? get error => _error;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Loads all cached notifications from device local storage.
  Future<void> loadLocalNotifications() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _notifications = await _repository.loadAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Synchronizes, derives, caches locally, and schedules notifications
  /// across the device for crops, animals, and weather alerts.
  Future<void> syncAndSchedule({
    required List<Crop> crops,
    required List<Animal> animals,
    WeatherData? weather,
    bool isBn = false,
  }) async {
    try {
      // 1. Derive fresh notifications
      final derived = _repository.deriveNotifications(
        crops: crops,
        animals: animals,
        weather: weather,
      );

      // 2. Merge with locally saved ones and persist
      _notifications = await _repository.mergeAndSave(derived);

      // 3. Schedule device popup alerts for future notifications
      for (final n in _notifications) {
        if (!n.isRead) {
          await _service.scheduleAppNotification(n, isBn: isBn);
        }
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('Error in syncAndSchedule notifications: $e');
    }
  }

  /// Marks a specific notification as read.
  Future<void> markAsRead(String id) async {
    await _repository.markAsRead(id);
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _notifications[idx] = _notifications[idx].copyWith(isRead: true);
      notifyListeners();
    }
  }

  /// Marks all notifications as read.
  Future<void> markAllAsRead() async {
    await _repository.markAllAsRead();
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();
  }

  /// Manually adds and triggers an immediate or scheduled notification.
  Future<void> addAndSchedule(AppNotification notification, {bool isBn = false}) async {
    _notifications = await _repository.mergeAndSave([notification]);
    await _service.scheduleAppNotification(notification, isBn: isBn);
    notifyListeners();
  }
}
