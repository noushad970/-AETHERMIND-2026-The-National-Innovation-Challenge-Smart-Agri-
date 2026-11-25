import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../data/models/animal.dart';
import '../../../../data/repositories/livestock_repository.dart';
import '../../../../data/services/livestock_hive_service.dart';
import '../../../../data/services/livestock_realtime_service.dart';
import '../../data/livestock_activity_templates.dart';

/// UI-facing state for the signed-in user's livestock groups.
///
/// Reads and writes synchronize simultaneously across Cloud Firestore
/// and local Hive database for instant offline support and daily sync.
class LivestockProvider extends ChangeNotifier {
  LivestockProvider({
    LivestockRepository? repository,
    LivestockRealtimeService? realtime,
  }) : _repo = repository ?? LivestockRepository(),
       _realtime = realtime ?? LivestockRealtimeService() {
    _animalsSub = _realtime.stream().listen(_onAnimals);
    _realtime.addListener(_onRealtimeChanged);
    // 1. Seed the UI immediately from Hive cached snapshot
    _animals = _realtime.snapshot;

    // 2. Perform daily sync once per day on launch
    _checkDailySync();
  }

  final LivestockRepository _repo;
  final LivestockRealtimeService _realtime;

  StreamSubscription<List<Animal>>? _animalsSub;

  /// Latest in-memory mirror of the realtime service snapshot.
  List<Animal> _animals = const [];

  DateTime? _lastSyncedAt;
  bool _isRefreshing = false;
  bool _disposed = false;

  // ─── Public reads ─────────────────────────────────────────────

  List<Animal> get animals => List<Animal>.unmodifiable(_animals);

  int get count => _animals.length;

  int get totalLiveCount =>
      _animals.fold<int>(0, (sum, a) => sum + a.liveCount);

  int get totalDeaths => _animals.fold<int>(0, (sum, a) => sum + a.deadCount);

  Animal? byId(String id) {
    for (final a in _animals) {
      if (a.id == id) return a;
    }
    return null;
  }

  bool get isLoading => _animals.isEmpty && _lastSyncedAt == null;

  bool get isRefreshing => _isRefreshing;

  DateTime? get lastSyncedAt => _lastSyncedAt;

  // ─── Writes ───────────────────────────────────────────────────

  Future<void> save(Animal animal) async {
    await _repo.add(animal);
    _realtime.invalidate();
    _touchSyncedAt();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    _realtime.invalidate();
    _touchSyncedAt();
  }

  /// Toggle a single activity for [animalId]. Delegates to the
  /// repository so the recurring-occurrence logic + animal mirror
  /// stay in one place.
  ///
  /// Applies an **optimistic** in-memory mutation before the
  /// Firestore roundtrip so the UI re-renders instantly. If the
  /// Firestore write fails the realtime listener will echo the
  /// server-truthy state back and the optimistic state is
  /// overwritten.
  Future<LivestockActivity?> toggleActivity(
    String animalId,
    String activityId,
    bool done,
  ) async {
    // Optimistic in-memory flip so the CheckboxListTile reflects
    // the new state immediately (no Firestore round-trip latency).
    _applyOptimisticToggle(animalId, activityId, done);
    LivestockActivity? result;
    try {
      result = await _repo.toggleActivity(activityId: activityId, done: done);
    } catch (e) {
      // Roll back the optimistic state if the write failed so the
      // UI doesn't lie.
      _applyOptimisticToggle(animalId, activityId, !done);
      rethrow;
    }
    _realtime.invalidate();
    _touchSyncedAt();
    // Notify the daily-suggestions provider so the AI cache
    // staleness check picks up the new checklist state on next
    // read; the suggestion will be regenerated lazily.
    _suggestionRefreshHook?.call(animalId);
    return result;
  }

  /// Optional callback fired after a successful checklist toggle.
  /// The provider exposes this so [main.dart] (or any
  /// composition root) can hook the AI-suggestion refresh without
  /// this provider depending on the suggestion provider directly
  /// (keeps the dependency arrow one-way).
  void Function(String animalId)? _suggestionRefreshHook;

  /// Register a hook that runs after every successful toggle. The
  /// hook is expected to be the
  /// [LivestockDailySuggestionsProvider.ensureToday] adapter.
  void setSuggestionRefreshHook(void Function(String animalId) hook) {
    _suggestionRefreshHook = hook;
  }

  void _applyOptimisticToggle(String animalId, String activityId, bool done) {
    final idx = _animals.indexWhere((a) => a.id == animalId);
    if (idx == -1) return;
    final animal = _animals[idx];
    final aIdx = animal.activities.indexWhere((a) => a.id == activityId);
    if (aIdx == -1) return;
    final toggled = animal.activities[aIdx];
    toggled.isCompleted = done;
    toggled.completedAt = done ? DateTime.now() : null;
    // Mutating the field in place is enough — the Animal object is
    // a mutable reference shared with the detail screen, and
    // notifyListeners triggers a Consumer rebuild that re-reads
    // the same list. Still bump the list reference so any
    // reference-equality checks (the realtime sync handler does
    // `identical(snap, _animals)`) correctly register the change.
    _animals = List<Animal>.of(_animals);
    notifyListeners();
  }

  /// Record [count] new deaths against [animalId]. Clamped to total
  /// count so the live head-count never goes negative.
  Future<({int live, int died})> recordDeaths(
    String animalId,
    int count,
  ) async {
    final result = await _repo.recordDeaths(animalId: animalId, count: count);
    _realtime.invalidate();
    _touchSyncedAt();
    return result;
  }

  /// Bumps the realtime snapshot (forces a re-emit) and refreshes
  /// the last-synced timestamp with direct server fetch.
  Future<void> refreshFromCloud() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    notifyListeners();
    try {
      final fetched = await _realtime.fetchDirect();
      if (fetched.isNotEmpty) {
        _animals = fetched;
        await LivestockHiveService.instance.saveAnimals(fetched);
      }
      _realtime.invalidate();
      _touchSyncedAt();
    } catch (_) {
      _realtime.invalidate();
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  /// Automatically executes daily sync once per 24 hours between
  /// Cloud Firestore and local Hive database.
  Future<void> _checkDailySync() async {
    if (LivestockHiveService.instance.isDailySyncNeededToday()) {
      await syncDailyOnce();
    }
  }

  /// Manually or automatically performs a full synchronization between
  /// Cloud Firestore and Hive database, updating all animal groups and daily records.
  Future<void> syncDailyOnce() async {
    try {
      await refreshFromCloud();
      await LivestockHiveService.instance.recordDailySyncCompleted();
      debugPrint('[LivestockProvider] Daily sync with Cloud Firestore & Hive completed successfully.');
    } catch (e) {
      debugPrint('[LivestockProvider] Daily sync failed: $e');
    }
  }

  void _onAnimals(List<Animal> list) {
    if (_disposed) return;
    for (final a in list) {
      if (a.activities.isEmpty) {
        final acts = LivestockActivityTemplates.build(
          animalId: a.id,
          species: a.species,
          purpose: a.purpose,
          startDate: a.startDate,
        );
        if (acts.isNotEmpty) {
          a.activities = acts;
          _repo.add(a);
        }
      }
    }
    _animals = list;
    _touchSyncedAt();
  }

  void _onRealtimeChanged() {
    if (_disposed) return;
    final snap = _realtime.snapshot;
    if (identical(snap, _animals)) return;
    _animals = snap;
    notifyListeners();
  }

  void _touchSyncedAt() {
    if (_disposed) return;
    _lastSyncedAt = DateTime.now();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _animalsSub?.cancel();
    _realtime.removeListener(_onRealtimeChanged);
    super.dispose();
  }
}
