import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../../../../data/models/animal.dart';
import '../../../../data/models/livestock_daily_summary.dart';
import '../../../../data/models/livestock_daily_suggestion.dart';
import '../../../../data/repositories/livestock_daily_suggestion_repository.dart';
import '../../../../data/services/gemini_service.dart';
import '../../../../data/services/livestock_children_service.dart';

/// Owns the per-animal AI daily suggestion state. Mirrors
/// [DailySuggestionsProvider] for crops but is keyed by animal id.
///
/// Reads come from the [LivestockChildrenService] Firestore stream
/// (today's record resolution), writes go through Gemini + the
/// repository.
class LivestockDailySuggestionsProvider extends ChangeNotifier {
  LivestockDailySuggestionsProvider({
    LivestockDailySuggestionRepository? repository,
    GeminiService? gemini,
    LivestockChildrenService? realtime,
  }) : _repo = repository ?? LivestockDailySuggestionRepository(),
       _gemini = gemini ?? GeminiService(),
       _realtime = realtime ?? LivestockChildrenService() {
    // Mirror the Firestore stream into the in-memory map: any new
    // suggestion arriving server-side is reflected immediately.
    _realtime.addListener(_onRealtimeChanged);
  }

  final LivestockDailySuggestionRepository _repo;
  final GeminiService _gemini;
  final LivestockChildrenService _realtime;
  bool _disposed = false;

  /// animalId -> today's (or latest cached) suggestion.
  final Map<String, LivestockDailySuggestion> _byAnimal =
      <String, LivestockDailySuggestion>{};

  /// animalId -> true while a Gemini call is in flight.
  final Map<String, bool> _loading = <String, bool>{};

  /// animalId -> last error message (cleared on next successful fetch).
  final Map<String, String> _errors = <String, String>{};

  /// animalId -> most recent summary snapshot used for staleness checks.
  final Map<String, Map<String, dynamic>> _currentSnapshots =
      <String, Map<String, dynamic>>{};

  LivestockDailySuggestion? suggestionFor(String animalId) =>
      _byAnimal[animalId];
  bool isLoading(String animalId) => _loading[animalId] ?? false;
  String? errorFor(String animalId) => _errors[animalId];

  /// True when the in-memory cache already holds a record whose
  /// `dateKey` matches today's local date. Detail screens call this
  /// before invoking [ensureToday] so a same-day reopen doesn't
  /// trigger an extra Gemini call — the card just renders the
  /// Firestore doc that the daily-updater wrote earlier.
  bool hasFreshTodayRecord(String animalId) {
    final s = _byAnimal[animalId];
    if (s == null) return false;
    return s.dateKey == LivestockDailySuggestion.dateKeyFor(DateTime.now());
  }

  bool isStaleFor(String animalId) {
    final s = _byAnimal[animalId];
    final cur = _currentSnapshots[animalId];
    if (s == null || cur == null) return false;
    return _repo.isStale(s, cur);
  }

  /// Re-derive the in-memory map from the realtime service. Called
  /// whenever a snapshot arrives so previously-loaded animals get
  /// up-to-date suggestions without waiting for [ensureToday] to be
  /// called again.
  void reloadAll() {
    _byAnimal.clear();
    for (final animalId in _repo.allAnimalIdsWithSuggestions()) {
      final today = _repo.todayFor(animalId);
      if (today != null) {
        _byAnimal[animalId] = today;
      } else {
        final latest = _repo.latestFor(animalId);
        if (latest != null) _byAnimal[animalId] = latest;
      }
    }
    notifyListeners();
  }

  /// Cheap read of today's record from the realtime service. Does
  /// NOT call Gemini.
  void primeFromCache(String animalId) {
    if (_byAnimal.containsKey(animalId)) return;
    final today = _repo.todayFor(animalId);
    if (today != null) {
      _byAnimal[animalId] = today;
      notifyListeners();
    }
  }

  /// Returns the existing today's record if it's still relevant, or
  /// fetches a fresh one from Gemini. Safe to call repeatedly.
  Future<void> ensureToday(
    Animal animal,
    LivestockDailySummary? summary,
  ) async {
    final today = _repo.todayFor(animal.id);
    final snapshot = _summarySnapshot(animal, summary);
    _currentSnapshots[animal.id] = snapshot;
    // A date-keyed Firestore document is the daily cache. Reopening this
    // screen or changing an activity must not call Gemini again.
    if (today != null) {
      _byAnimal[animal.id] = today;
      _errors.remove(animal.id);
      notifyListeners();
      return;
    }
    await refreshFor(animal, summary);
  }

  /// Force a fresh Gemini call for [animal] regardless of cache state.
  Future<void> refreshFor(Animal animal, LivestockDailySummary? summary) async {
    _loading[animal.id] = true;
    _errors.remove(animal.id);
    notifyListeners();

    final now = DateTime.now();
    final dateKey = LivestockDailySuggestion.dateKeyFor(now);
    final snapshot = _summarySnapshot(animal, summary);
    _currentSnapshots[animal.id] = snapshot;

    LivestockDailyAdvice advice;
    String source = 'gemini';
    try {
      advice = await _gemini.getLivestockGuidance(
        animal: animal,
        summary: summary,
        weatherSummary: _weatherSummaryFor(),
      );
    } catch (e) {
      developer.log(
        'Gemini livestock guidance failed: $e',
        name: 'LivestockDailySuggestionsProvider',
        error: e,
      );
      advice = _gemini.buildOfflineLivestockGuidance(
        animal: animal,
        summary: summary,
      );
      source = advice.source;
      _errors[animal.id] =
          'Showing offline guidance. Will retry on next refresh.';
    }

    final suggestion = LivestockDailySuggestion(
      id: LivestockDailySuggestion.buildId(animal.id, dateKey),
      animalId: animal.id,
      userId: animal.userId,
      dateKey: dateKey,
      dayFromStart: animal.daysSinceStart,
      species: animal.species,
      purpose: animal.purpose,
      guidance: advice.guidance,
      doItems: advice.doItems,
      dontItems: advice.dontItems,
      generatedAt: now,
      summarySnapshot: snapshot,
      source: source,
    );

    await _repo.save(suggestion);
    _byAnimal[animal.id] = suggestion;
    _loading[animal.id] = false;
    notifyListeners();
  }

  /// Removes the in-memory cache for an animal (used when the
  /// animal is deleted from the list screen).
  void forget(String animalId) {
    _byAnimal.remove(animalId);
    _loading.remove(animalId);
    _errors.remove(animalId);
    _currentSnapshots.remove(animalId);
    notifyListeners();
  }

  Map<String, dynamic> _summarySnapshot(
    Animal animal,
    LivestockDailySummary? summary,
  ) {
    // Build a digest of today's checklist state so the AI cache
    // invalidates as soon as the farmer ticks (or unticks) an
    // activity — the suggestion text is no longer relevant once
    // the day's checklist has shifted.
    final completedIds = <String>[];
    DateTime? lastCompletedAt;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    for (final a in animal.activities) {
      if (!a.isCompleted) continue;
      completedIds.add(a.id);
      final c = a.completedAt;
      if (c != null) {
        final cDay = DateTime(c.year, c.month, c.day);
        if (cDay == today &&
            (lastCompletedAt == null || c.isAfter(lastCompletedAt))) {
          lastCompletedAt = c;
        }
      }
    }
    completedIds.sort();
    return <String, dynamic>{
      'liveCount': animal.liveCount,
      'deadCount': animal.deadCount,
      'eggsToday': summary?.eggsToday ?? 0,
      'milkLitersToday': summary?.milkLitersToday ?? 0,
      'deathsToday': summary?.deathsToday ?? 0,
      'feedKg': summary?.feedKg ?? 0,
      'completedActivityIds': completedIds,
      'completedActivityCount': completedIds.length,
      'lastChecklistUpdateAt': lastCompletedAt?.toIso8601String(),
    };
  }

  String _weatherSummaryFor() {
    // Same decoupling as crops: weather provider is intentionally
    // not injected here. The offline fallback string keeps the
    // prompt well-formed.
    return 'Not available \u2014 give general advice for the season.';
  }

  // --- Realtime wiring --------------------------------------------------

  void _onRealtimeChanged() {
    if (_disposed) return;
    reloadAll();
  }

  @override
  void dispose() {
    _disposed = true;
    _realtime.removeListener(_onRealtimeChanged);
    super.dispose();
  }
}
