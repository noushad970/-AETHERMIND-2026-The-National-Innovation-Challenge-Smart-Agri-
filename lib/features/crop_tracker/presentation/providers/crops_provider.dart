import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../data/models/crop.dart';
import '../../../../data/services/crop_template_service.dart';
import '../../../../data/services/crops_realtime_service.dart';

/// Owns the live list of crops for the crop-tracker feature.
///
/// All reads come **directly from Cloud Firestore** through
/// [CropsRealtimeService] — there is no local cache. Writes go
/// through the **same** realtime service instance so the live
/// snapshot listener picks them up and the UI updates without
/// waiting for the next round-trip.
class CropsProvider extends ChangeNotifier {
  CropsProvider({CropsRealtimeService? realtime})
    : _realtime = realtime ?? CropsRealtimeService() {
    _subscribe();
  }

  final CropsRealtimeService _realtime;

  StreamSubscription<List<Crop>>? _sub;

  List<Crop> _crops = const [];
  bool _loading = true;
  String? _error;

  /// True while a manual cloud refresh is in flight (pull-only).
  bool _refreshing = false;
  bool get isRefreshing => _refreshing;

  /// Last time a successful pull finished. Null if we've never
  /// pulled. UI surfaces this in the list header so the user knows
  /// when the data was last synced.
  DateTime? _lastSyncedAt;
  DateTime? get lastSyncedAt => _lastSyncedAt;

  /// Latest realtime-stream error message, if any.
  String? get error => _error;
  String? get realtimeError => _realtime.lastError;
  void clearRealtimeError() => _realtime.clearError();

  List<Crop> get crops => _crops;
  bool get isLoading => _loading;
  int get count => _crops.length;

  /// Look up a single crop by id. Used by per-crop detail / live-track
  /// screens so they read directly from the in-memory snapshot rather
  /// than going back through the local cache.
  Crop? byId(String id) {
    for (final c in _crops) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// (Re)subscribe to the realtime crops stream. The realtime
  /// service watches Firebase auth on its own, so this single
  /// subscription keeps working across sign-in / sign-out.
  void _subscribe() {
    _sub?.cancel();
    _loading = true;
    _error = null;
    notifyListeners();
    _sub = _realtime.stream().listen(
      (crops) {
        for (final c in crops) {
          if (c.activities.isEmpty) {
            final acts = CropTemplateService.buildActivities(
              cropId: c.id,
              cropType: c.cropType,
              plantingDate: c.plantingDate,
              totalGrowthDays: c.totalGrowthDays,
            );
            if (acts.isNotEmpty) {
              c.activities = acts;
              _realtime.save(c);
            }
          }
        }
        _crops = crops;
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object e) {
        _error = e.toString();
        _loading = false;
        notifyListeners();
      },
    );
  }

  /// Manual pull from Firestore that forces a direct server fetch.
  Future<void> refreshFromCloud() async {
    if (_refreshing) return;
    _refreshing = true;
    notifyListeners();
    try {
      final fetched = await _realtime.fetchDirect();
      if (fetched.isNotEmpty) {
        _crops = fetched;
      }
      _realtime.invalidate();
      _lastSyncedAt = DateTime.now();
    } catch (_) {
      _realtime.invalidate();
    } finally {
      _refreshing = false;
      notifyListeners();
    }
  }

  /// Persists a crop change to Firestore. The realtime service
  /// writes to the cloud, updates its in-memory mirror and
  /// publishes the new list on its broadcast stream. The provider's
  /// stream listener picks that up and refreshes [_crops] so the
  /// UI sees the new crop immediately.
  Future<void> save(Crop crop) async {
    await _realtime.save(crop);
    // The stream listener won't fire until the next microtask, so
    // optimistically upsert here too. This keeps the detail screen
    // usable when the user navigates right after saving a new crop.
    _optimisticUpsert(crop);
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await _realtime.delete(id);
    _crops = _crops.where((c) => c.id != id).toList(growable: false);
    notifyListeners();
  }

  Future<void> toggleActivity(
    String cropId,
    String activityId,
    bool completed,
  ) async {
    final crop = byId(cropId);
    if (crop == null) return;
    final idx = crop.activities.indexWhere((a) => a.id == activityId);
    if (idx == -1) return;
    crop.activities[idx] = crop.activities[idx].copyWith(
      isCompleted: completed,
      completedAt: completed ? DateTime.now() : null,
    );
    await _realtime.save(crop);
    _optimisticUpsert(crop);
    notifyListeners();
  }

  Future<void> addTrees(String cropId, int count) async {
    final crop = byId(cropId);
    if (crop == null) return;
    crop.newlyPlantedTrees += count;
    await _realtime.save(crop);
    _optimisticUpsert(crop);
    notifyListeners();
  }

  Future<void> markDeadTrees(String cropId, int count) async {
    final crop = byId(cropId);
    if (crop == null) return;
    crop.deadTrees += count;
    await _realtime.save(crop);
    _optimisticUpsert(crop);
    notifyListeners();
  }

  /// Update the in-memory list with the new crop state so the UI
  /// reflects the write immediately, before the realtime listener
  /// echoes it back.
  void _optimisticUpsert(Crop crop) {
    final idx = _crops.indexWhere((c) => c.id == crop.id);
    final next = [..._crops];
    if (idx == -1) {
      next.add(crop);
    } else {
      next[idx] = crop;
    }
    next.sort((a, b) => b.plantingDate.compareTo(a.plantingDate));
    _crops = next;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
