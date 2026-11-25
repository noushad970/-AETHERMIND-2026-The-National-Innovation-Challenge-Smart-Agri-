import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';
import '../models/crop.dart';
import '../models/crop_activity.dart';
import 'crop_template_service.dart';
import 'crops_hive_service.dart';
import 'firestore_sync_service.dart';

/// Real-time crops service: streams the signed-in user's crops
/// directly from Cloud Firestore with instant Hive offline caching.
class CropsRealtimeService extends ChangeNotifier {
  CropsRealtimeService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirestoreSyncService? sync,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _sync = sync ?? FirestoreSyncService() {
    // 0ms instant local offline hydration from Hive
    _lastCrops = CropsHiveService.instance.getCrops();

    _authSub = _auth.authStateChanges().listen((u) => _onAuthChanged(u?.uid));

    final current = _auth.currentUser?.uid;
    if (current != null) _onAuthChanged(current);
  }

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirestoreSyncService _sync;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _cropsSub;

  String? _uid;
  String? _lastError;
  List<Crop> _lastCrops = const [];

  List<Crop> get snapshot => List<Crop>.unmodifiable(_lastCrops);

  String? get lastError => _lastError;

  String? get currentUid => _uid ?? _auth.currentUser?.uid;

  void clearError() {
    if (_lastError == null) return;
    _lastError = null;
    notifyListeners();
  }

  Stream<List<Crop>> stream() async* {
    yield _lastCrops;
    yield* _controller.stream;
  }

  final StreamController<List<Crop>> _controller =
      StreamController<List<Crop>>.broadcast();

  void _publish(List<Crop> crops) {
    _lastCrops = crops;
    // Persist to local Hive database
    CropsHiveService.instance.saveCrops(crops);
    if (!_controller.isClosed) _controller.add(crops);
    notifyListeners();
  }

  void _onAuthChanged(String? uid) {
    if (_uid == uid && _cropsSub != null) return;
    _uid = uid;
    _cropsSub?.cancel();
    _cropsSub = null;
    if (uid == null) {
      _publish(const []);
      return;
    }

    // Hydrate offline data first
    final cached = CropsHiveService.instance.getCrops();
    if (cached.isNotEmpty) {
      _publish(cached);
    }

    final col = _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection(AppConstants.cropsCollection);

    _bootstrap(col);

    _cropsSub = col.snapshots().listen(
      (snap) {
        _lastError = null;
        _publish(_fromSnapshot(snap));
      },
      onError: (Object e, StackTrace st) {
        developer.log(
          'Crops stream failed',
          name: 'CropsRealtimeService',
          error: e,
          stackTrace: st,
        );
        _lastError = 'Realtime crops sync failed: $e';
        notifyListeners();
      },
    );
  }

  List<Crop> fromSnapshot(QuerySnapshot<Map<String, dynamic>> snap) =>
      _fromSnapshot(snap);

  Future<List<Crop>> fetchDirect() async {
    final uid = currentUid;
    if (uid == null) return _lastCrops;
    final col = _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection(AppConstants.cropsCollection);
    final snap = await col.get();
    final list = _fromSnapshot(snap);
    _publish(list);
    return list;
  }

  Future<void> _bootstrap(CollectionReference<Map<String, dynamic>> col) async {
    try {
      final snap = await col.get();
      _publish(_fromSnapshot(snap));
    } catch (e, st) {
      developer.log(
        'Crops bootstrap get failed',
        name: 'CropsRealtimeService',
        error: e,
        stackTrace: st,
      );
    }
  }

  List<Crop> _fromSnapshot(QuerySnapshot<Map<String, dynamic>> snap) {
    final out = <Crop>[];
    for (final doc in snap.docs) {
      final data = doc.data();
      data['id'] = doc.id;
      try {
        out.add(_cropFromMap(data));
      } catch (e) {
        developer.log(
          'Skipping malformed crop ${doc.id}: $e',
          name: 'CropsRealtimeService',
        );
      }
    }
    out.sort((a, b) => b.plantingDate.compareTo(a.plantingDate));
    return out;
  }

  Crop _cropFromMap(Map<String, dynamic> m) {
    final activitiesRaw = m['activities'];
    final List<CropActivity> activities = [];
    if (activitiesRaw is List) {
      for (final a in activitiesRaw) {
        if (a is Map) {
          try {
            activities.add(CropActivity.fromMap(Map<String, dynamic>.from(a)));
          } catch (_) {}
        }
      }
    }

    final id = (m['id'] ?? '').toString();
    final cropType = (m['cropType'] ?? '').toString();
    final plantingDate = _parseDate(m['plantingDate']) ?? DateTime.now();
    final totalGrowthDays = _toInt(m['totalGrowthDays']) ?? 0;

    if (activities.isEmpty && cropType.isNotEmpty) {
      final generated = CropTemplateService.buildActivities(
        cropId: id,
        cropType: cropType,
        plantingDate: plantingDate,
        totalGrowthDays: totalGrowthDays,
      );
      if (generated.isNotEmpty) {
        activities.addAll(generated);
      }
    }

    final crop = Crop(
      id: id,
      userId: (m['userId'] ?? _uid ?? _auth.currentUser?.uid ?? '').toString(),
      cropType: cropType,
      variety: (m['variety'] ?? '').toString(),
      plantingDate: plantingDate,
      landAreaDecimal: _toDouble(m['landAreaDecimal']),
      totalGrowthDays: totalGrowthDays,
      estimatedHarvestDate:
          _parseDate(m['estimatedHarvestDate']) ??
          DateTime.now().add(const Duration(days: 90)),
      numberOfTrees: _toInt(m['numberOfTrees']),
      notes: (m['notes'] ?? '').toString(),
      imageUrl: m['imageUrl'] as String?,
      healthStatus: (m['healthStatus'] ?? 'good').toString(),
      activities: activities,
      newlyPlantedTrees: _toInt(m['newlyPlantedTrees']) ?? 0,
    );
    final deadTrees = _toInt(m['deadTrees']);
    if (deadTrees != null) crop.deadTrees = deadTrees;
    return crop;
  }

  DateTime? _parseDate(Object? v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String) {
      return DateTime.tryParse(v);
    }
    if (v is num) {
      return DateTime.fromMillisecondsSinceEpoch(v.toInt());
    }
    if (v is Map) {
      final secs = v['_seconds'];
      if (secs is num) {
        return DateTime.fromMillisecondsSinceEpoch(secs.toInt() * 1000);
      }
    }
    return null;
  }

  double _toDouble(Object? v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  int? _toInt(Object? v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  void invalidate() {
    final u = currentUid;
    if (u != null && _cropsSub == null) {
      _onAuthChanged(u);
    }
    _publish(_lastCrops);
  }

  Future<void> save(Crop crop) async {
    final uid = _uid ?? _auth.currentUser?.uid ?? crop.userId;
    if (uid.isEmpty) return;
    if (_uid == null) {
      _uid = uid;
      _onAuthChanged(uid);
    }
    crop.userId = uid;
    await _sync.upsertCrop(crop);
    _upsertMirror(crop);
    _publish(_lastCrops);
  }

  Future<void> delete(String id) async {
    final uid = _uid ?? _auth.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) {
      _uid ??= uid;
      await _sync.deleteCrop(id);
    }
    _lastCrops = _lastCrops.where((c) => c.id != id).toList(growable: false);
    _publish(_lastCrops);
  }

  void _upsertMirror(Crop crop) {
    final idx = _lastCrops.indexWhere((c) => c.id == crop.id);
    final next = [..._lastCrops];
    if (idx == -1) {
      next.add(crop);
    } else {
      next[idx] = crop;
    }
    next.sort((a, b) => b.plantingDate.compareTo(a.plantingDate));
    _lastCrops = next;
  }

  @override
  void dispose() {
    _cropsSub?.cancel();
    _authSub?.cancel();
    _controller.close();
    super.dispose();
  }
}
