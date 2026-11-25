import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';
import '../models/fish_pond.dart';
import 'fish_hive_service.dart';
import 'firestore_sync_service.dart';

/// Realtime Firestore subscription service for user fish ponds with Hive offline caching.
class FishRealtimeService extends ChangeNotifier {
  FishRealtimeService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirestoreSyncService? syncService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _sync = syncService ?? FirestoreSyncService() {
    // 0ms instant local offline hydration from Hive
    _ponds = FishHiveService.instance.getPonds();
    _loading = _ponds.isEmpty;

    _authSub = _auth.authStateChanges().listen(_onAuthChanged);
  }

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirestoreSyncService _sync;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _fishSub;

  List<FishPond> _ponds = [];
  List<FishPond> get ponds => List.unmodifiable(_ponds);

  bool _loading = true;
  bool get isLoading => _loading;

  String? _error;
  String? get error => _error;

  int get totalPonds => _ponds.length;
  int get totalFingerlings =>
      _ponds.fold(0, (acc, p) => acc + p.fingerlingCount);
  int get totalLiveFish => _ponds.fold(0, (acc, p) => acc + p.liveCount);

  void _onAuthChanged(User? user) {
    _fishSub?.cancel();
    _fishSub = null;

    if (user == null) {
      _ponds = [];
      _loading = false;
      _error = null;
      notifyListeners();
      return;
    }

    final cached = FishHiveService.instance.getPonds();
    if (cached.isNotEmpty) {
      _ponds = cached;
      _loading = false;
      notifyListeners();
    } else {
      _loading = true;
      notifyListeners();
    }

    final query = _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .collection(AppConstants.fishPondsCollection)
        .orderBy('stockingDate', descending: true);

    _fishSub = query.snapshots().listen(
      (snapshot) {
        _ponds =
            snapshot.docs
                .map((doc) {
                  try {
                    final data = doc.data();
                    data['id'] = doc.id;
                    return FishPond.fromMap(data);
                  } catch (e) {
                    debugPrint('Error parsing FishPond doc ${doc.id}: $e');
                    return null;
                  }
                })
                .whereType<FishPond>()
                .toList();

        // Persist to local Hive database
        FishHiveService.instance.savePonds(_ponds);

        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (err) {
        _error = err.toString();
        _loading = false;
        notifyListeners();
      },
    );
  }

  FishPond? getById(String id) {
    try {
      return _ponds.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addPond(FishPond pond) async {
    final user = _auth.currentUser;
    if (user != null) {
      pond.userId = user.uid;
    }
    // Optimistic local add
    final index = _ponds.indexWhere((p) => p.id == pond.id);
    if (index >= 0) {
      _ponds[index] = pond;
    } else {
      _ponds.insert(0, pond);
    }
    notifyListeners();

    await _sync.upsertFishPond(pond);
  }

  Future<void> updatePond(FishPond pond) async {
    final index = _ponds.indexWhere((p) => p.id == pond.id);
    if (index >= 0) {
      _ponds[index] = pond;
      notifyListeners();
    }
    await _sync.upsertFishPond(pond);
  }

  Future<void> deletePond(String pondId) async {
    _ponds.removeWhere((p) => p.id == pondId);
    notifyListeners();
    await _sync.deleteFishPond(pondId);
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _fishSub?.cancel();
    super.dispose();
  }
}
