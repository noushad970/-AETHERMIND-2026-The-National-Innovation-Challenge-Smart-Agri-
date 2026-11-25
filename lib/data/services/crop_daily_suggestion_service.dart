import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';
import '../models/daily_suggestion.dart';
import 'firestore_sync_service.dart';

/// Streams the signed-in user's crop daily AI suggestions from
/// Firestore. Subcollection path:
///   users/{uid}/crops/{cropId}/dailySuggestions/{dateKey}
class CropDailySuggestionService extends ChangeNotifier {
  CropDailySuggestionService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirestoreSyncService? sync,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _sync = sync ?? FirestoreSyncService() {
    _authSub = _auth.authStateChanges().listen((u) => _onAuthChanged(u?.uid));
    final current = _auth.currentUser?.uid;
    if (current != null) _onAuthChanged(current);
  }

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirestoreSyncService _sync;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _cropsSub;
  final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
  _suggestionsSubs = {};

  String? _uid;
  String? _lastError;
  final Map<String, List<DailySuggestion>> _suggestionsByCrop = {};

  String? get lastError => _lastError;
  void clearError() {
    if (_lastError == null) return;
    _lastError = null;
    notifyListeners();
  }

  List<DailySuggestion> suggestionsFor(String cropId) =>
      List<DailySuggestion>.unmodifiable(
        _suggestionsByCrop[cropId] ?? const [],
      );

  DailySuggestion? latestFor(String cropId) {
    final all = suggestionsFor(cropId);
    if (all.isEmpty) return null;
    return all.first;
  }

  DailySuggestion? todayFor(String cropId) {
    final dateKey = DailySuggestion.dateKeyFor(DateTime.now());
    return _suggestionsByCrop[cropId]
        ?.where((s) => s.dateKey == dateKey)
        .cast<DailySuggestion?>()
        .firstWhere((_) => true, orElse: () => null);
  }

  Set<String> get cropIdsWithSuggestions => _suggestionsByCrop.keys.toSet();

  void _onAuthChanged(String? uid) {
    if (_uid == uid) return;
    _uid = uid;
    _cropsSub?.cancel();
    _cropsSub = null;
    _cancelAll();
    _suggestionsByCrop.clear();
    if (uid == null) {
      notifyListeners();
      return;
    }

    final cropsCol = _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection(AppConstants.cropsCollection);

    _cropsSub = cropsCol.snapshots().listen(
      (snap) {
        _lastError = null;
        final keepSubs = <String>{};
        for (final doc in snap.docs) {
          keepSubs.add(doc.id);
          if (!_suggestionsSubs.containsKey(doc.id)) {
            _subscribeSuggestions(doc.id);
          }
        }
        // Cancel subscriptions for crops removed server-side.
        final removed = _suggestionsSubs.keys
            .where((k) => !keepSubs.contains(k))
            .toList();
        for (final k in removed) {
          _suggestionsSubs[k]?.cancel();
          _suggestionsSubs.remove(k);
          _suggestionsByCrop.remove(k);
        }
        notifyListeners();
      },
      onError: (Object e, StackTrace st) {
        developer.log(
          'Crops daily-suggestions stream failed',
          name: 'CropDailySuggestionService',
          error: e,
          stackTrace: st,
        );
        _lastError = 'Realtime daily-suggestion sync failed: $e';
        notifyListeners();
      },
    );
  }

  void _cancelAll() {
    for (final s in _suggestionsSubs.values) {
      s.cancel();
    }
    _suggestionsSubs.clear();
  }

  void _subscribeSuggestions(String cropId) {
    final col = _firestore
        .collection(AppConstants.usersCollection)
        .doc(_uid)
        .collection(AppConstants.cropsCollection)
        .doc(cropId)
        .collection(AppConstants.dailySuggestionsCollection);
    _suggestionsSubs[cropId] = col.snapshots().listen(
      (snap) {
        final out = <DailySuggestion>[];
        for (final doc in snap.docs) {
          final data = doc.data();
          data['id'] = doc.id;
          try {
            out.add(DailySuggestion.fromMap(data));
          } catch (e) {
            developer.log(
              'Skipping malformed daily suggestion ${doc.id}: $e',
              name: 'CropDailySuggestionService',
            );
          }
        }
        out.sort((a, b) => b.generatedAt.compareTo(a.generatedAt));
        _suggestionsByCrop[cropId] = out;
        notifyListeners();
      },
      onError: (Object e, StackTrace st) {
        developer.log(
          'Daily suggestion stream failed for $cropId',
          name: 'CropDailySuggestionService',
          error: e,
          stackTrace: st,
        );
      },
    );
  }

  void invalidate() => notifyListeners();

  Future<void> save(DailySuggestion suggestion) async {
    if (_uid == null) return;
    await _sync.upsertDailySuggestion(suggestion);
    invalidate();
  }

  Future<void> delete({required String cropId, required String dateKey}) async {
    if (_uid == null) return;
    await _sync.deleteDailySuggestion(cropId: cropId, dateKey: dateKey);
    invalidate();
  }

  @override
  void dispose() {
    _cancelAll();
    _cropsSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }
}
