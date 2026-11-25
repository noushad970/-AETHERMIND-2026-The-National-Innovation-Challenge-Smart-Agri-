import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../../../../data/models/weather_data.dart';
import '../../../../data/models/weather_daily_advice.dart';
import '../../../../data/repositories/weather_daily_advice_repository.dart';
import '../../../../data/services/gemini_service.dart';
import '../providers/weather_provider.dart';

/// Owns the per-user daily AI weather tip. The current record is
/// always available synchronously to the UI from [current]; it is
/// re-hydrated from Firestore on every snapshot change so a fresh
/// tip written by the daily updater appears immediately.
///
/// The provider is intentionally tolerant: the user may be signed out
/// (no tip generated yet), may have never opened the weather tab
/// (no realtime stream), or may be in an offline region (fallback
/// advice). In all cases [current] is non-null after the first
/// [ensureToday] call.
class WeatherDailyAdviceProvider extends ChangeNotifier {
  WeatherDailyAdviceProvider({
    WeatherDailyAdviceRepository? repository,
    GeminiService? gemini,
    WeatherProvider? weather,
    String? userId,
  }) : _repo = repository ?? WeatherDailyAdviceRepository(),
       _gemini = gemini ?? GeminiService(),
       _weather = weather,
       _userId = userId {
    if (_weather != null) {
      _weather!.addListener(_onWeatherChanged);
    }
  }

  final WeatherDailyAdviceRepository _repo;
  final GeminiService _gemini;
  WeatherProvider? _weather;
  String? _userId;
  StreamSubscription<WeatherDailyAdvice?>? _sub;

  WeatherDailyAdvice? _current;
  bool _loading = false;
  String? _error;
  bool _disposed = false;

  WeatherDailyAdvice? get current => _current;
  bool get isLoading => _loading;
  String? get error => _error;

  /// True when [current] already holds a record whose `dateKey`
  /// matches today's local date. Used by the weather screen to skip
  /// a redundant `ensureToday` call on first paint when the daily
  /// updater has already written today's doc.
  bool hasFreshTodayRecordCached() {
    final c = _current;
    if (c == null) return false;
    return c.dateKey == WeatherDailyAdvice.dateKeyFor(DateTime.now());
  }

  /// Called by main.dart once the user signs in. Switches the
  /// realtime subscription over to the signed-in user id and primes
  /// today's record from the cache.
  Future<void> bindUser(String? userId) async {
    if (_userId == userId) return;
    _userId = userId;
    await _sub?.cancel();
    _sub = null;
    _current = null;
    notifyListeners();
    if (userId == null) return;
    _sub = _repo.watchForToday(userId).listen(_onSnapshot);
    final cached = await _repo.todayFor(userId);
    if (cached != null) {
      _current = cached;
      notifyListeners();
    }
  }

  /// Convenience setter for the [WeatherProvider] reference when the
  /// DI tree is constructed lazily.
  void bindWeather(WeatherProvider w) {
    if (identical(_weather, w)) return;
    if (_weather != null) {
      _weather!.removeListener(_onWeatherChanged);
    }
    _weather = w;
    _weather!.addListener(_onWeatherChanged);
  }

  /// Returns today's record if it exists in cache, otherwise asks
  /// Gemini to generate one. Safe to call repeatedly — the cache
  /// short-circuit runs first.
  ///
  /// [weather] is the snapshot we hand to Gemini. If not provided
  /// we fall back to whatever the bound [WeatherProvider] currently
  /// holds, which keeps the updater's call signature simple.
  Future<void> ensureToday({WeatherData? weather}) async {
    final uid = _userId;
    if (uid == null) {
      _error = 'Sign in to see today\'s weather tip.';
      notifyListeners();
      return;
    }
    final today = await _repo.todayFor(uid);
    if (today != null &&
        today.dateKey == WeatherDailyAdvice.dateKeyFor(DateTime.now())) {
      _current = today;
      _error = null;
      notifyListeners();
      return;
    }
    await refresh(weather: weather);
  }

  /// Force a fresh Gemini call for today's tip.
  Future<void> refresh({WeatherData? weather}) async {
    final uid = _userId;
    if (uid == null) return;
    final w = weather ?? _weather?.data;
    if (w == null) {
      _error = 'Waiting for weather data — try again in a moment.';
      notifyListeners();
      return;
    }
    _loading = true;
    _error = null;
    notifyListeners();

    final now = DateTime.now();
    final dateKey = WeatherDailyAdvice.dateKeyFor(now);
    final snapshot = <String, dynamic>{
      'locationName': w.locationName,
      'latitude': w.latitude,
      'longitude': w.longitude,
      'temperatureC': w.temperatureC,
      'feelsLikeC': w.feelsLikeC,
      'humidity': w.humidity,
      'windKph': w.windSpeedKmh,
      'precipMm': w.precipitationMm,
      'conditionLabel': w.conditionLabel,
    };

    DailyWeatherAdvice advice;
    String source = 'gemini';
    try {
      advice = await _gemini.getDailyWeatherAdvice(weather: snapshot);
      if (advice.isOffline) source = 'fallback';
    } catch (e) {
      developer.log(
        'Gemini weather advice failed: $e',
        name: 'WeatherDailyAdviceProvider',
        error: e,
      );
      advice = _gemini.buildOfflineWeatherAdvice(weather: snapshot);
      source = 'fallback';
      _error = 'Showing offline guidance. Will retry on next refresh.';
    }

    final doc = WeatherDailyAdvice(
      id: WeatherDailyAdvice.buildId(uid, dateKey),
      userId: uid,
      dateKey: dateKey,
      headline: advice.headline,
      summary: advice.summary,
      doItems: advice.doItems,
      dontItems: advice.dontItems,
      weatherSnapshot: snapshot,
      generatedAt: now,
      source: source,
    );
    try {
      await _repo.save(doc);
      // The realtime listener will receive the snapshot, but write
      // it locally too so the UI updates before the stream emits.
      _current = doc;
    } catch (e) {
      developer.log(
        'Failed to persist weather advice: $e',
        name: 'WeatherDailyAdviceProvider',
        error: e,
      );
      _error = 'Could not save today\'s tip — try again later.';
    }
    _loading = false;
    notifyListeners();
  }

  void _onSnapshot(WeatherDailyAdvice? snap) {
    if (_disposed) return;
    _current = snap;
    notifyListeners();
  }

  void _onWeatherChanged() {
    if (_disposed) return;
    // The weather just refreshed; if we don't yet have today's tip,
    // opportunistically kick off a generation so the card lights up
    // as soon as data is available.
    if (_current == null && _userId != null && !_loading) {
      ensureToday();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _sub?.cancel();
    if (_weather != null) {
      _weather!.removeListener(_onWeatherChanged);
    }
    super.dispose();
  }
}
