import 'package:flutter/foundation.dart';
import '../../../../data/models/fish_activity.dart';
import '../../../../data/models/fish_daily_summary.dart';
import '../../../../data/models/fish_pond.dart';
import '../../../../data/services/fish_children_service.dart';
import '../../../../data/services/fish_realtime_service.dart';

class FishProvider extends ChangeNotifier {
  FishProvider({
    required FishRealtimeService realtime,
    required FishChildrenService children,
  }) : _realtime = realtime,
       _children = children {
    _realtime.addListener(_onRealtimeChanged);
    _children.addListener(_onChildrenChanged);
  }

  final FishRealtimeService _realtime;
  final FishChildrenService _children;

  List<FishPond> get ponds => _realtime.ponds;
  bool get isLoading => _realtime.isLoading;
  String? get error => _realtime.error;

  int get totalPonds => _realtime.totalPonds;
  int get totalFingerlings => _realtime.totalFingerlings;
  int get totalLiveFish => _realtime.totalLiveFish;

  FishPond? getPond(String id) => _realtime.getById(id);

  List<FishActivity> getActivities(String pondId) =>
      _children.getActivities(pondId);

  List<FishDailySummary> getSummaries(String pondId) =>
      _children.getSummaries(pondId);

  void bindPond(String pondId) {
    _children.bindPond(pondId);
  }

  Future<void> addPond(FishPond pond) async {
    await _realtime.addPond(pond);
  }

  Future<void> updatePond(FishPond pond) async {
    await _realtime.updatePond(pond);
  }

  Future<void> deletePond(String pondId) async {
    await _realtime.deletePond(pondId);
  }

  Future<void> toggleActivity(
    String pondId,
    String activityId,
    bool isCompleted,
  ) async {
    await _children.toggleActivity(pondId, activityId, isCompleted);
  }

  Future<void> recordDailySummary(FishDailySummary summary) async {
    await _children.addSummary(summary);
  }

  void _onRealtimeChanged() {
    notifyListeners();
  }

  void _onChildrenChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _realtime.removeListener(_onRealtimeChanged);
    _children.removeListener(_onChildrenChanged);
    super.dispose();
  }
}
