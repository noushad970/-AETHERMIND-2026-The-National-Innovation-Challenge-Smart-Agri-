import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/weather_daily_advice.dart';

/// Firestore persistence for [WeatherDailyAdvice]. Documents live in
/// `weatherDailyAdvice/{userId}_{dateKey}`. The shape is intentionally
/// one-doc-per-user-per-day so reads are O(1) and writes don't fight
/// concurrent updaters from multiple devices.
class WeatherDailyAdviceRepository {
  WeatherDailyAdviceRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  static const String _collection = 'weatherDailyAdvice';

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(_collection);

  /// Returns today's record if it exists in Firestore. O(1) read.
  Future<WeatherDailyAdvice?> getForDate(String userId, DateTime date) async {
    final id = WeatherDailyAdvice.buildId(
      userId,
      WeatherDailyAdvice.dateKeyFor(date),
    );
    final snap = await _col.doc(id).get();
    if (!snap.exists) return null;
    final data = snap.data();
    if (data == null) return null;
    return WeatherDailyAdvice.fromMap(data);
  }

  /// Upserts [advice]. Returns when the write is acknowledged.
  Future<void> save(WeatherDailyAdvice advice) async {
    await _col.doc(advice.id).set(advice.toMap());
  }

  /// Stream that re-emits today's record whenever Firestore changes it.
  /// Used by [WeatherDailyAdviceProvider] so the UI updates in real
  /// time when the daily-updater writes a fresh tip.
  Stream<WeatherDailyAdvice?> watchForToday(String userId) {
    final id = WeatherDailyAdvice.buildId(
      userId,
      WeatherDailyAdvice.dateKeyFor(DateTime.now()),
    );
    return _col.doc(id).snapshots().map((snap) {
      if (!snap.exists) return null;
      final data = snap.data();
      if (data == null) return null;
      return WeatherDailyAdvice.fromMap(data);
    });
  }

  /// Convenience: today's record, or null if nothing has been cached.
  Future<WeatherDailyAdvice?> todayFor(String userId) =>
      getForDate(userId, DateTime.now());
}
