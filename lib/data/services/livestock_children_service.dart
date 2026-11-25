import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';
import '../models/livestock_daily_summary.dart';
import '../models/livestock_daily_suggestion.dart';
import '../models/animal.dart';
import 'firestore_sync_service.dart';
import 'livestock_hive_service.dart';

/// Real-time livestock subcollection service: streams per-animal
/// activities, daily summaries, and daily AI suggestions from
/// Firestore and caches them in Hive for instantaneous offline performance.
class LivestockChildrenService extends ChangeNotifier {
  LivestockChildrenService({
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
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _animalsSub;
  final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
  _activitiesSubs = {};
  final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
  _summariesSubs = {};
  final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
  _suggestionsSubs = {};

  String? _uid;
  final Map<String, List<LivestockActivity>> _activitiesByAnimal = {};
  final Map<String, List<LivestockDailySummary>> _summariesByAnimal = {};
  final Map<String, List<LivestockDailySuggestion>> _suggestionsByAnimal = {};
  String? _lastError;

  String? get lastError => _lastError;
  void clearError() {
    if (_lastError == null) return;
    _lastError = null;
    notifyListeners();
  }

  /// Activities for a single animal, ordered by scheduled date.
  List<LivestockActivity> activitiesFor(String animalId) {
    final inMemory = _activitiesByAnimal[animalId];
    if (inMemory != null && inMemory.isNotEmpty) {
      return List<LivestockActivity>.unmodifiable(inMemory);
    }
    final cached = LivestockHiveService.instance.getActivities(animalId);
    if (cached.isNotEmpty) {
      _activitiesByAnimal[animalId] = cached;
      return List<LivestockActivity>.unmodifiable(cached);
    }
    return const [];
  }

  /// Daily summaries for a single animal, ordered by date key.
  List<LivestockDailySummary> summariesFor(String animalId) {
    final inMemory = _summariesByAnimal[animalId];
    if (inMemory != null && inMemory.isNotEmpty) {
      return List<LivestockDailySummary>.unmodifiable(inMemory);
    }
    final cached = LivestockHiveService.instance.getDailySummaries(animalId);
    if (cached.isNotEmpty) {
      _summariesByAnimal[animalId] = cached;
      return List<LivestockDailySummary>.unmodifiable(cached);
    }
    return const [];
  }

  /// Daily AI suggestions for a single animal, newest first.
  List<LivestockDailySuggestion> suggestionsFor(String animalId) {
    final inMemory = _suggestionsByAnimal[animalId];
    if (inMemory != null && inMemory.isNotEmpty) {
      return List<LivestockDailySuggestion>.unmodifiable(inMemory);
    }
    final cached = LivestockHiveService.instance.getDailySuggestions(animalId);
    if (cached.isNotEmpty) {
      _suggestionsByAnimal[animalId] = cached;
      return List<LivestockDailySuggestion>.unmodifiable(cached);
    }
    return const [];
  }

  LivestockDailySummary? latestSummaryFor(String animalId) {
    final all = summariesFor(animalId);
    if (all.isEmpty) return null;
    return all.last;
  }

  LivestockDailySuggestion? latestSuggestionFor(String animalId) {
    final all = suggestionsFor(animalId);
    if (all.isEmpty) return null;
    return all.first;
  }

  /// All animal ids that have any child data on the server. Used
  /// by the daily-suggestion provider to know which animals need
  /// AI work.
  Set<String> get animalIdsWithData {
    final set = <String>{};
    set.addAll(_activitiesByAnimal.keys);
    set.addAll(_summariesByAnimal.keys);
    set.addAll(_suggestionsByAnimal.keys);
    return set;
  }

  void _onAuthChanged(String? uid) {
    if (_uid == uid) return;
    _uid = uid;
    _animalsSub?.cancel();
    _animalsSub = null;
    _cancelAll(_activitiesSubs);
    _cancelAll(_summariesSubs);
    _cancelAll(_suggestionsSubs);
    _activitiesByAnimal.clear();
    _summariesByAnimal.clear();
    _suggestionsByAnimal.clear();
    if (uid == null) {
      notifyListeners();
      return;
    }

    final animalsCol = _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection(AppConstants.livestockCollection);

    _animalsSub = animalsCol.snapshots().listen(
      (snap) {
        _lastError = null;
        final keepSubs = <String>{};
        for (final doc in snap.docs) {
          keepSubs.add(doc.id);
          _subscribeChildren(doc.id);
        }
        _pruneSubs(keepSubs);
        notifyListeners();
      },
      onError: (Object e, StackTrace st) {
        developer.log(
          'Livestock animals stream failed',
          name: 'LivestockChildrenService',
          error: e,
          stackTrace: st,
        );
        _lastError = 'Realtime livestock sync failed: $e';
        notifyListeners();
      },
    );
  }

  void _cancelAll(
    Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>> m,
  ) {
    for (final s in m.values) {
      s.cancel();
    }
    m.clear();
  }

  void _pruneSubs(Set<String> keep) {
    void prune(
      Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>> m,
      Map<String, List<dynamic>> data,
    ) {
      final removed = m.keys.where((k) => !keep.contains(k)).toList();
      for (final k in removed) {
        m[k]?.cancel();
        m.remove(k);
        data.remove(k);
      }
    }

    prune(_activitiesSubs, _activitiesByAnimal);
    prune(_summariesSubs, _summariesByAnimal);
    prune(_suggestionsSubs, _suggestionsByAnimal);
  }

  void _subscribeChildren(String animalId) {
    final animalRef = _firestore
        .collection(AppConstants.usersCollection)
        .doc(_uid)
        .collection(AppConstants.livestockCollection)
        .doc(animalId);

    if (!_activitiesSubs.containsKey(animalId)) {
      _activitiesSubs[animalId] = animalRef
          .collection(AppConstants.livestockActivitiesCollection)
          .snapshots()
          .listen(
            (snap) {
              final out = <LivestockActivity>[];
              for (final doc in snap.docs) {
                final data = doc.data();
                data['id'] = doc.id;
                try {
                  out.add(LivestockActivity.fromMap(data));
                } catch (e) {
                  developer.log(
                    'Skipping malformed activity ${doc.id}: $e',
                    name: 'LivestockChildrenService',
                  );
                }
              }
              out.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
              _activitiesByAnimal[animalId] = out;
              // Mirror activities in Hive
              LivestockHiveService.instance.saveActivities(animalId, out);
              notifyListeners();
            },
            onError: (Object e, StackTrace st) {
              developer.log(
                'Livestock activities stream failed for $animalId',
                name: 'LivestockChildrenService',
                error: e,
                stackTrace: st,
              );
            },
          );
    }

    if (!_summariesSubs.containsKey(animalId)) {
      _summariesSubs[animalId] = animalRef
          .collection(AppConstants.livestockDailySummariesCollection)
          .snapshots()
          .listen(
            (snap) {
              final out = <LivestockDailySummary>[];
              for (final doc in snap.docs) {
                final data = doc.data();
                data['id'] = doc.id;
                try {
                  out.add(LivestockDailySummary.fromMap(data));
                } catch (e) {
                  developer.log(
                    'Skipping malformed summary ${doc.id}: $e',
                    name: 'LivestockChildrenService',
                  );
                }
              }
              out.sort((a, b) => a.dateKey.compareTo(b.dateKey));
              _summariesByAnimal[animalId] = out;
              // Mirror daily summaries in Hive
              LivestockHiveService.instance.saveDailySummaries(animalId, out);
              notifyListeners();
            },
            onError: (Object e, StackTrace st) {
              developer.log(
                'Livestock summaries stream failed for $animalId',
                name: 'LivestockChildrenService',
                error: e,
                stackTrace: st,
              );
            },
          );
    }

    if (!_suggestionsSubs.containsKey(animalId)) {
      _suggestionsSubs[animalId] = animalRef
          .collection(AppConstants.livestockDailySuggestionsCollection)
          .snapshots()
          .listen(
            (snap) {
              final out = <LivestockDailySuggestion>[];
              for (final doc in snap.docs) {
                final data = doc.data();
                data['id'] = doc.id;
                try {
                  out.add(LivestockDailySuggestion.fromMap(data));
                } catch (e) {
                  developer.log(
                    'Skipping malformed suggestion ${doc.id}: $e',
                    name: 'LivestockChildrenService',
                  );
                }
              }
              out.sort((a, b) => b.generatedAt.compareTo(a.generatedAt));
              _suggestionsByAnimal[animalId] = out;
              // Mirror daily suggestions in Hive
              LivestockHiveService.instance.saveDailySuggestions(animalId, out);
              notifyListeners();
            },
            onError: (Object e, StackTrace st) {
              developer.log(
                'Livestock suggestions stream failed for $animalId',
                name: 'LivestockChildrenService',
                error: e,
                stackTrace: st,
              );
            },
          );
    }
  }

  /// Bump local caches so any UI listening on this service refreshes
  /// after a write. Real Firestore writes will arrive via the
  /// listeners above and overwrite these values anyway.
  void invalidate() => notifyListeners();

  /// Activity toggle. Pushes to Hive immediately and synchronizes with Firestore.
  Future<LivestockActivity?> toggleActivity({
    required Animal animal,
    required LivestockActivity activity,
  }) async {
    // 1. Immediately save to Hive
    await LivestockHiveService.instance.saveActivity(activity);
    
    // 2. Sync with Firebase Firestore
    if (_uid != null) {
      await _sync.toggleLivestockActivity(animal: animal, activity: activity);
    }
    invalidate();
    return activity;
  }

  Future<void> upsertDailySummary(LivestockDailySummary summary) async {
    // 1. Immediately save to Hive
    await LivestockHiveService.instance.saveDailySummary(summary);
    
    // 2. Sync with Firebase Firestore
    if (_uid != null) {
      await _sync.upsertLivestockSummary(summary);
    }
    invalidate();
  }

  Future<void> deleteDailySummary({
    required String livestockId,
    required String dateKey,
  }) async {
    if (_uid != null) {
      await _sync.deleteLivestockDailySummary(
        livestockId: livestockId,
        dateKey: dateKey,
      );
    }
    invalidate();
  }

  Future<void> upsertDailySuggestion(
    LivestockDailySuggestion suggestion,
  ) async {
    // 1. Immediately save to Hive
    await LivestockHiveService.instance.saveDailySuggestion(suggestion);

    // 2. Sync with Firebase Firestore
    if (_uid != null) {
      await _sync.upsertLivestockDailySuggestion(
        livestockId: suggestion.animalId,
        suggestion: suggestion,
      );
    }
    invalidate();
  }

  Future<void> deleteDailySuggestion({
    required String livestockId,
    required String dateKey,
  }) async {
    if (_uid != null) {
      await _sync.deleteLivestockDailySuggestion(
        livestockId: livestockId,
        dateKey: dateKey,
      );
    }
    invalidate();
  }

  @override
  void dispose() {
    for (final s in _activitiesSubs.values) {
      s.cancel();
    }
    for (final s in _summariesSubs.values) {
      s.cancel();
    }
    for (final s in _suggestionsSubs.values) {
      s.cancel();
    }
    _activitiesSubs.clear();
    _summariesSubs.clear();
    _suggestionsSubs.clear();
    _animalsSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }
}
