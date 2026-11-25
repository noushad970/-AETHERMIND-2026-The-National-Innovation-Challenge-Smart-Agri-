import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../../../../data/models/crop.dart';
import '../../../../data/models/crop_activity.dart';
import '../../../../data/models/daily_suggestion.dart';
import '../../../../data/repositories/daily_suggestion_repository.dart';
import '../../../../data/services/crop_daily_suggestion_service.dart';
import '../../../../data/services/gemini_service.dart';

/// Owns the per-crop AI daily suggestion state.
///
/// Strategy:
///   * Today's suggestion is read from the [CropDailySuggestionService]
///     Firestore stream so the UI is never empty when the user
///     re-opens a crop on any device.
///   * [ensureToday] is the only way to *generate* a new suggestion.
///     It first asks the repository for today's record; if it exists
///     it's reused without calling Gemini (cheap reopens).
///   * The crop-detail screen also calls [ensureToday] whenever a
///     checklist item is toggled, so the user sees the AI re-evaluate
///     their progress in near-real-time.
///   * The daily-updater service listens on [CropsRealtimeService]
///     and invokes [ensureToday] for every crop whose today's record
///     is still missing, so newly-added crops get their card without
///     the user having to open the detail screen.
class DailySuggestionsProvider extends ChangeNotifier {
  DailySuggestionsProvider({
    DailySuggestionRepository? repository,
    GeminiService? gemini,
    CropDailySuggestionService? realtime,
  }) : _repo = repository ?? DailySuggestionRepository(),
       _gemini = gemini ?? GeminiService(),
       _realtime = realtime ?? CropDailySuggestionService() {
    // Mirror the Firestore stream into our local cache: every time
    // the service publishes a new snapshot, re-derive today's
    // record for each known crop.
    _realtime.addListener(_onRealtimeChanged);
  }

  final DailySuggestionRepository _repo;
  final GeminiService _gemini;
  final CropDailySuggestionService _realtime;
  bool _disposed = false;

  /// cropId -> today's suggestion (or the latest cached one if today is
  /// missing). The UI reads from this map synchronously.
  final Map<String, DailySuggestion> _byCrop = <String, DailySuggestion>{};

  /// cropId -> true while a Gemini call is in flight. Used to drive a
  /// "thinking…" indicator without blocking the UI.
  final Map<String, bool> _loading = <String, bool>{};

  /// cropId -> last error message (cleared on next successful fetch).
  final Map<String, String> _errors = <String, String>{};

  /// cropId -> most recently observed checklist. Refreshed every time
  /// [ensureToday] / [refreshFor] is called so [isStaleFor] can detect
  /// when the user toggles something *after* a suggestion was already
  /// generated.
  final Map<String, List<({String id, bool isCompleted})>> _currentChecklist =
      <String, List<({String id, bool isCompleted})>>{};

  DailySuggestion? suggestionFor(String cropId) => _byCrop[cropId];
  bool isLoading(String cropId) => _loading[cropId] ?? false;
  String? errorFor(String cropId) => _errors[cropId];

  /// True when the in-memory cache already holds a record whose
  /// `dateKey` matches today's local date. Detail screens call this
  /// before invoking [ensureToday] so a same-day reopen doesn't
  /// trigger an extra Gemini call — the card just renders the
  /// Firestore doc that the daily-updater wrote earlier.
  bool hasFreshTodayRecord(String cropId) {
    final s = _byCrop[cropId];
    if (s == null) return false;
    return s.dateKey == DailySuggestion.dateKeyFor(DateTime.now());
  }

  /// True if a stored suggestion exists for [cropId] but its
  /// checklist snapshot no longer matches the last checklist we saw.
  /// The UI uses this to show a small "stale — refresh" badge.
  bool isStaleFor(String cropId) {
    final s = _byCrop[cropId];
    final cur = _currentChecklist[cropId];
    if (s == null || cur == null) return false;
    return _repo.isStale(s, cur);
  }

  /// Re-derive the in-memory map from the realtime service. Called
  /// whenever the service emits a new snapshot (auth change, new
  /// crop, Firestore write). Keeps today's record visible in the
  /// UI even when [refreshFor] hasn't been triggered.
  void reloadAll() {
    _byCrop.clear();
    for (final cropId in _repo.allCropIdsWithSuggestions()) {
      final today = _repo.todayFor(cropId);
      if (today != null) {
        _byCrop[cropId] = today;
      } else {
        // Fall back to the latest suggestion if today's record is
        // missing — the UI then shows "this is yesterday's advice"
        // rather than an empty card. A brand-new crop may have no
        // stored suggestion yet (the subcollection snapshot is
        // empty), so skip it instead of crashing on a null value.
        final latest = _repo.latestFor(cropId);
        if (latest != null) _byCrop[cropId] = latest;
      }
    }
    notifyListeners();
  }

  /// Cheap read of today's record from the realtime service. Does
  /// NOT call Gemini. Called once at the top of
  /// `crop_detail_screen.build` so the card is never empty during
  /// the first paint. We don't know the live checklist here, so the
  /// stale check stays disabled until [ensureToday] is called.
  void primeFromCache(String cropId) {
    if (_byCrop.containsKey(cropId)) return;
    final today = _repo.todayFor(cropId);
    if (today != null) {
      _byCrop[cropId] = today;
      notifyListeners();
    }
  }

  /// Returns the existing today's record if it's still relevant, or
  /// fetches a fresh one from Gemini. Safe to call repeatedly — the
  /// provider short-circuits when nothing has changed.
  Future<void> ensureToday(Crop crop) async {
    final today = _repo.todayFor(crop.id);
    final current = _checklistTuples(crop);
    _currentChecklist[crop.id] = current;
    // A date-keyed Firestore document is the daily cache. Reopening this
    // screen or changing a checklist item must not call Gemini again.
    if (today != null) {
      _byCrop[crop.id] = today;
      _errors.remove(crop.id);
      notifyListeners();
      return;
    }
    await refreshFor(crop);
  }

  /// Force a fresh Gemini call for [crop] regardless of cache state.
  Future<void> refreshFor(Crop crop) async {
    _loading[crop.id] = true;
    _errors.remove(crop.id);
    notifyListeners();

    final now = DateTime.now();
    final dateKey = DailySuggestion.dateKeyFor(now);
    final checklist = crop.activities
        .map(
          (a) => {
            'id': a.id,
            'title': a.title,
            'dayFromPlanting': a.dayFromPlanting,
            'isCompleted': a.isCompleted,
            'category': a.category,
          },
        )
        .toList(growable: false);
    final checklistSnapshot = checklist
        .map(
          (m) => {
            'id': m['id'],
            'title': m['title'],
            'isCompleted': m['isCompleted'],
          },
        )
        .toList(growable: false);
    _currentChecklist[crop.id] = _checklistTuples(crop);

    DailyCropAdvice advice;
    String source = 'gemini';
    try {
      advice = await _gemini.getDailyCropAdvice(
        cropType: crop.cropType,
        variety: crop.variety.isEmpty ? crop.cropType : crop.variety,
        dayFromPlanting: crop.daysSincePlanting,
        growthStage: crop.currentGrowthStage,
        checklist: checklist,
        weatherSummary: _weatherSummaryFor(crop),
        landAreaDecimal: crop.landAreaDecimal,
        numberOfTrees: crop.numberOfTrees,
        deadTrees: crop.deadTrees,
        newlyPlantedTrees: crop.newlyPlantedTrees,
        daysRemainingUntilHarvest: crop.daysRemainingUntilHarvest,
        notes: crop.notes.isEmpty ? null : crop.notes,
      );
    } catch (e) {
      developer.log(
        'Gemini daily advice failed: $e',
        name: 'DailySuggestionsProvider',
        error: e,
      );
      advice = _gemini.buildOfflineAdvice(
        cropType: crop.cropType,
        dayFromPlanting: crop.daysSincePlanting,
        checklist: checklist,
      );
      source = 'fallback';
      _errors[crop.id] =
          'Showing offline guidance. Will retry on next refresh.';
    }

    final suggestion = DailySuggestion(
      id: DailySuggestion.buildId(crop.id, dateKey),
      cropId: crop.id,
      userId: crop.userId,
      dateKey: dateKey,
      dayFromPlanting: crop.daysSincePlanting,
      cropType: crop.cropType,
      variety: crop.variety,
      guidance: advice.guidance,
      doItems: advice.doItems,
      dontItems: advice.dontItems,
      generatedAt: now,
      checklistSnapshot: checklistSnapshot,
      source: source,
    );

    await _repo.save(suggestion);
    _byCrop[crop.id] = suggestion;
    _loading[crop.id] = false;
    notifyListeners();
  }

  /// Removes the in-memory cache for a crop (used when the crop is
  /// deleted from the list screen so the next open doesn't briefly
  /// show a stale card).
  void forget(String cropId) {
    _byCrop.remove(cropId);
    _loading.remove(cropId);
    _errors.remove(cropId);
    _currentChecklist.remove(cropId);
    notifyListeners();
  }

  // --- Helpers ----------------------------------------------------------

  List<({String id, bool isCompleted})> _checklistTuples(Crop crop) {
    return crop.activities
        .map((CropActivity a) => (id: a.id, isCompleted: a.isCompleted))
        .toList(growable: false);
  }

  /// Reads today's weather summary from the in-memory cache if the
  /// weather provider has already loaded it. Falls back to a neutral
  /// string when we don't have weather yet — Gemini still produces
  /// useful guidance without it.
  String _weatherSummaryFor(Crop crop) {
    // The WeatherProvider is intentionally not injected here to keep
    // this provider independent. If a future iteration wires it up,
    // it can populate this string. For now the offline fallback
    // string keeps the prompt well-formed.
    return 'Not available — give general advice for the season.';
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
