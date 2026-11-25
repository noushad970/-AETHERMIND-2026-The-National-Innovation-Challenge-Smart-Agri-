import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_notification.dart';
import '../models/crop.dart';
import '../models/animal.dart';
import '../models/weather_data.dart';
import '../../core/constants/app_strings.dart';

class LocalNotificationRepository {
  static const String _storageKey = 'agri_local_notifications_v1';

  /// Loads all cached notifications from local storage.
  Future<List<AppNotification>> loadAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => AppNotification.fromMap(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading local notifications: $e');
      return [];
    }
  }

  /// Persists a list of notifications to local storage.
  Future<void> saveAll(List<AppNotification> notifications) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(notifications.map((n) => n.toMap()).toList());
      await prefs.setString(_storageKey, raw);
    } catch (e) {
      if (kDebugMode) debugPrint('Error saving local notifications: $e');
    }
  }

  /// Adds or updates notifications in local storage without wiping existing ones.
  Future<List<AppNotification>> mergeAndSave(
    List<AppNotification> incoming,
  ) async {
    final current = await loadAll();
    final map = {for (final n in current) n.id: n};
    for (final n in incoming) {
      if (map.containsKey(n.id)) {
        // Keep user read status if already marked
        final existing = map[n.id]!;
        map[n.id] = n.copyWith(isRead: existing.isRead);
      } else {
        map[n.id] = n;
      }
    }
    final merged = map.values.toList()
      ..sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));
    await saveAll(merged);
    return merged;
  }

  /// Marks a specific notification as read.
  Future<void> markAsRead(String id) async {
    final list = await loadAll();
    final updated = list.map((n) {
      return n.id == id ? n.copyWith(isRead: true) : n;
    }).toList();
    await saveAll(updated);
  }

  /// Marks all notifications as read.
  Future<void> markAllAsRead() async {
    final list = await loadAll();
    final updated = list.map((n) => n.copyWith(isRead: true)).toList();
    await saveAll(updated);
  }

  /// Clears all local notifications.
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  /// Derives fresh notifications from crops, livestock, and weather.
  List<AppNotification> deriveNotifications({
    required List<Crop> crops,
    required List<Animal> animals,
    WeatherData? weather,
  }) {
    final results = <AppNotification>[];
    final now = DateTime.now();

    // 1. Crop Activities
    for (final c in crops) {
      for (final a in c.activities) {
        final id = 'crop_act_${c.id}_${a.id}';
        results.add(
          AppNotification(
            id: id,
            titleEn: '${AppStrings.reminderPrefix}${a.title}',
            titleBn: '${AppStrings.reminderPrefixBn}${a.title}',
            bodyEn: a.description.isNotEmpty
                ? '${c.cropType}: ${a.description}'
                : '${c.cropType} (${c.variety}) - Task scheduled for Day ${a.dayFromPlanting}.',
            bodyBn: a.description.isNotEmpty
                ? '${c.cropType}: ${a.description}'
                : '${c.cropType} (${c.variety}) - ${a.dayFromPlanting}তম দিনের নির্ধারিত কাজ।',
            type: NotificationType.cropReminder,
            scheduledTime: a.scheduledDate,
            isRead: a.isCompleted,
            route: '/crop_detail',
            routeArgument: c.id,
            metadata: {
              'cropId': c.id,
              'activityId': a.id,
              'category': a.category,
            },
          ),
        );
      }
    }

    // 2. Livestock Activities
    for (final animal in animals) {
      for (final a in animal.activities) {
        final id = 'livestock_act_${animal.id}_${a.id}';
        results.add(
          AppNotification(
            id: id,
            titleEn: '${AppStrings.reminderPrefix}${a.title}',
            titleBn: '${AppStrings.reminderPrefixBn}${a.title}',
            bodyEn: a.description.isNotEmpty
                ? '${animal.species} (${animal.purpose}): ${a.description}'
                : '${animal.species} - Scheduled routine task.',
            bodyBn: a.description.isNotEmpty
                ? '${animal.species} (${animal.purpose}): ${a.description}'
                : '${animal.species} - নিয়মিত নির্ধারিত কাজ।',
            type: NotificationType.livestockReminder,
            scheduledTime: a.scheduledDate,
            isRead: a.isCompleted,
            route: '/livestock_detail',
            routeArgument: animal.id,
            metadata: {
              'animalId': animal.id,
              'activityId': a.id,
              'category': a.category,
            },
          ),
        );
      }
    }

    // 3. Weather Alerts (if precip > 10mm or strong heat > 35C)
    if (weather != null) {
      if (weather.precipitationMm > 10.0 || weather.weatherCode >= 80) {
        final id = 'weather_rain_${now.year}_${now.month}_${now.day}';
        results.add(
          AppNotification(
            id: id,
            titleEn: 'Rain / Storm Warning',
            titleBn: 'বৃষ্টি ও ঝড়ের সতর্কবার্তা',
            bodyEn:
                'High precipitation expected in ${weather.locationName}. Ensure proper farm drainage and shelter for livestock.',
            bodyBn:
                '${weather.locationName} এলাকায় ভারী বৃষ্টির সম্ভাবনা। ফসলের জমিতে পানি নিষ্কাশন এবং গবাদি পশুর নিরাপদ আশ্রয় নিশ্চিত করুন।',
            type: NotificationType.weatherAlert,
            scheduledTime: now,
            route: '/weather',
          ),
        );
      } else if (weather.temperatureC > 35.0) {
        final id = 'weather_heat_${now.year}_${now.month}_${now.day}';
        results.add(
          AppNotification(
            id: id,
            titleEn: 'Heat Wave Advisory',
            titleBn: 'তীব্র তাপপ্রবাহের পরামর্শ',
            bodyEn:
                'Temperature is ${weather.temperatureC.toStringAsFixed(1)}°C. Provide adequate irrigation and shade for your livestock.',
            bodyBn:
                'তাপমাত্রা ${weather.temperatureC.toStringAsFixed(1)}°C। জমিতে সময়মতো সেচ দিন এবং পশুপাখির জন্য পর্যাপ্ত পানির ব্যবস্থা রাখুন।',
            type: NotificationType.weatherAlert,
            scheduledTime: now,
            route: '/weather',
          ),
        );
      }
    }

    return results;
  }
}
