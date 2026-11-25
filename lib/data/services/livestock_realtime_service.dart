import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';
import '../../features/livestock/data/livestock_activity_templates.dart';
import '../models/animal.dart';
import 'firestore_sync_service.dart';
import 'livestock_hive_service.dart';

/// Real-time livestock service: streams the signed-in user's animal
/// groups directly from Cloud Firestore and mirrors them locally with Hive.
class LivestockRealtimeService extends ChangeNotifier {
  LivestockRealtimeService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirestoreSyncService? sync,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _sync = sync ?? FirestoreSyncService() {
    // 1. Instant offline hydration from Hive database
    final cached = LivestockHiveService.instance.getAnimals();
    if (cached.isNotEmpty) {
      _lastAnimals = cached;
    }

    _authSub = _auth.authStateChanges().listen((u) => _onAuthChanged(u?.uid));

    final current = _auth.currentUser?.uid;
    if (current != null) _onAuthChanged(current);
  }

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirestoreSyncService _sync;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _livestockSub;

  String? _uid;
  String? _lastError;
  List<Animal> _lastAnimals = const [];

  List<Animal> get snapshot => List<Animal>.unmodifiable(_lastAnimals);

  String? get lastError => _lastError;

  String? get currentUid => _uid ?? _auth.currentUser?.uid;

  void clearError() {
    if (_lastError == null) return;
    _lastError = null;
    notifyListeners();
  }

  Stream<List<Animal>> stream() async* {
    yield _lastAnimals;
    yield* _controller.stream;
  }

  final StreamController<List<Animal>> _controller =
      StreamController<List<Animal>>.broadcast();

  void _publish(List<Animal> animals) {
    _lastAnimals = animals;
    // Persist latest livestock groups to Hive
    LivestockHiveService.instance.saveAnimals(animals);
    if (!_controller.isClosed) _controller.add(animals);
    notifyListeners();
  }

  void _onAuthChanged(String? uid) {
    if (_uid == uid && _livestockSub != null) return;
    _uid = uid;
    _livestockSub?.cancel();
    _livestockSub = null;
    if (uid == null) {
      _publish(const []);
      return;
    }

    final col = _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection(AppConstants.livestockCollection);

    _bootstrap(col);

    _livestockSub = col.snapshots().listen(
      (snap) {
        _lastError = null;
        _publish(_fromSnapshot(snap));
      },
      onError: (Object e, StackTrace st) {
        developer.log(
          'Livestock stream failed',
          name: 'LivestockRealtimeService',
          error: e,
          stackTrace: st,
        );
        _lastError = 'Realtime livestock sync failed: $e';
        notifyListeners();
      },
    );
  }

  List<Animal> fromSnapshot(QuerySnapshot<Map<String, dynamic>> snap) =>
      _fromSnapshot(snap);

  Future<List<Animal>> fetchDirect() async {
    final uid = currentUid;
    if (uid == null) return _lastAnimals;
    final col = _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection(AppConstants.livestockCollection);
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
        'Livestock bootstrap get failed',
        name: 'LivestockRealtimeService',
        error: e,
        stackTrace: st,
      );
    }
  }

  List<Animal> _fromSnapshot(QuerySnapshot<Map<String, dynamic>> snap) {
    final out = <Animal>[];
    for (final doc in snap.docs) {
      final data = doc.data();
      data['id'] = doc.id;
      try {
        out.add(_animalFromMap(data));
      } catch (e) {
        developer.log(
          'Skipping malformed animal ${doc.id}: $e',
          name: 'LivestockRealtimeService',
        );
      }
    }
    out.sort((a, b) => b.startDate.compareTo(a.startDate));
    return out;
  }

  Animal _animalFromMap(Map<String, dynamic> m) {
    final activitiesRaw = m['activities'];
    final List<LivestockActivity> activities = [];
    if (activitiesRaw is List) {
      for (final a in activitiesRaw) {
        if (a is Map) {
          try {
            activities.add(
              LivestockActivity.fromMap(Map<String, dynamic>.from(a)),
            );
          } catch (_) {}
        }
      }
    }

    final id = (m['id'] ?? '').toString();
    final species = (m['species'] ?? '').toString();
    final purpose = (m['purpose'] ?? AppConstants.purposeMixed).toString();
    final startDate = _parseDate(m['startDate']) ?? DateTime.now();

    if (activities.isEmpty && species.isNotEmpty) {
      final generated = LivestockActivityTemplates.build(
        animalId: id,
        species: species,
        purpose: purpose,
        startDate: startDate,
      );
      if (generated.isNotEmpty) {
        activities.addAll(generated);
      }
    }

    return Animal(
      id: id,
      userId: (m['userId'] ?? _uid ?? _auth.currentUser?.uid ?? '').toString(),
      species: species,
      purpose: purpose,
      startDate: startDate,
      totalCount: _toInt(m['totalCount']) ?? 0,
      deadCount: _toInt(m['deadCount']) ?? 0,
      notes: (m['notes'] ?? '').toString(),
      activities: activities,
    );
  }

  DateTime? _parseDate(Object? v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
    if (v is Map) {
      final secs = v['_seconds'];
      if (secs is num) {
        return DateTime.fromMillisecondsSinceEpoch(secs.toInt() * 1000);
      }
    }
    return null;
  }

  int? _toInt(Object? v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  void invalidate() {
    final u = currentUid;
    if (u != null && _livestockSub == null) {
      _onAuthChanged(u);
    }
    _publish(_lastAnimals);
  }

  Future<void> save(Animal animal) async {
    final uid = _uid ?? _auth.currentUser?.uid ?? animal.userId;
    if (uid.isEmpty) return;
    if (_uid == null) {
      _uid = uid;
      _onAuthChanged(uid);
    }
    animal.userId = uid;
    // 1. Immediately save to Hive
    await LivestockHiveService.instance.saveAnimal(animal);
    // 2. Sync to Firebase Firestore
    await _sync.upsertLivestock(animal);
    _upsertMirror(animal);
    _publish(_lastAnimals);
  }

  Future<void> delete(String id) async {
    // 1. Immediately delete from Hive
    await LivestockHiveService.instance.deleteAnimal(id);
    // 2. Delete from Firebase Firestore
    final uid = _uid ?? _auth.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) {
      _uid ??= uid;
      await _sync.deleteLivestock(id);
    }
    _lastAnimals = _lastAnimals
        .where((a) => a.id != id)
        .toList(growable: false);
    _publish(_lastAnimals);
  }

  void _upsertMirror(Animal animal) {
    final idx = _lastAnimals.indexWhere((a) => a.id == animal.id);
    final next = [..._lastAnimals];
    if (idx == -1) {
      next.add(animal);
    } else {
      next[idx] = animal;
    }
    next.sort((a, b) => b.startDate.compareTo(a.startDate));
    _lastAnimals = next;
  }

  @override
  void dispose() {
    _livestockSub?.cancel();
    _authSub?.cancel();
    _controller.close();
    super.dispose();
  }
}
