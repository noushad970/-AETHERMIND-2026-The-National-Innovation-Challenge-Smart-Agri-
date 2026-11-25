import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/models/crop.dart';
import '../../../data/services/crops_realtime_service.dart';

/// Lightweight read-only summary used by the home dashboard.
///
/// Subscribes to the same [CropsRealtimeService] that drives
/// [CropsProvider]. The home dashboard's "active crops" count and
/// "recent crops" list refresh automatically — without the user
/// having to navigate to the dedicated crop list.
class CropSummaryProvider extends ChangeNotifier {
  CropSummaryProvider({CropsRealtimeService? realtime})
    : _realtime = realtime ?? CropsRealtimeService() {
    _subscribe();
  }

  final CropsRealtimeService _realtime;

  StreamSubscription<List<Crop>>? _sub;

  bool _isLoading = true;
  List<Crop> _all = const [];
  List<Crop> _recent = const [];

  /// True while a manual cloud refresh is in flight.
  bool _refreshing = false;
  bool get isRefreshing => _refreshing;

  /// Last time a successful cloud pull finished. Null if we've never
  /// pulled. UI surfaces this in the home header so the user knows
  /// when the data was last synced.
  DateTime? _lastSyncedAt;
  DateTime? get lastSyncedAt => _lastSyncedAt;

  bool get isLoading => _isLoading;
  int get activeCropCount => _all.length;
  List<Crop> get recent => _recent;
  List<Crop> get all => _all;

  /// (Re)subscribe to the realtime crops stream. The Firestore side
  /// is the single source of truth — every add/update/delete is
  /// picked up here without any manual refresh.
  void _subscribe() {
    _sub?.cancel();
    _isLoading = true;
    notifyListeners();
    _sub = _realtime.stream().listen(
      (crops) {
        _all = crops;
        _recent = crops.take(3).toList(growable: false);
        _isLoading = false;
        notifyListeners();
      },
      onError: (Object _) {
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Re-subscribe to the realtime stream. Called from the home
  /// screen's pull-to-refresh.
  void refresh() {
    _subscribe();
  }

  /// Manual pull from Firestore. Mostly a no-op now that the stream
  /// is always live, but kept so the UI's existing "sync" button
  /// still bumps the [lastSyncedAt] indicator.
  Future<void> refreshFromCloud() async {
    if (_refreshing) return;
    _refreshing = true;
    notifyListeners();
    try {
      _realtime.invalidate();
      _lastSyncedAt = DateTime.now();
    } finally {
      _refreshing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
