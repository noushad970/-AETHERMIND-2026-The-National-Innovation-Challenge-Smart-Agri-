import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';
import '../models/fish_activity.dart';
import '../models/fish_daily_suggestion.dart';
import '../models/fish_daily_summary.dart';
import 'firestore_sync_service.dart';

/// Realtime subcollection service for fish activities, daily metrics, and AI suggestions.
class FishChildrenService extends ChangeNotifier {
  FishChildrenService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirestoreSyncService? syncService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _sync = syncService ?? FirestoreSyncService() {
    _authSub = _auth.authStateChanges().listen(_onAuthChanged);
  }

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirestoreSyncService _sync;

  StreamSubscription<User?>? _authSub;
  final Map<String, StreamSubscription> _activitySubs = {};
  final Map<String, StreamSubscription> _summarySubs = {};
  final Map<String, StreamSubscription> _suggestionSubs = {};

  final Map<String, List<FishActivity>> _activitiesByPond = {};
  final Map<String, List<FishDailySummary>> _summariesByPond = {};
  final Map<String, List<FishDailySuggestion>> _suggestionsByPond = {};

  List<FishActivity> getActivities(String pondId) =>
      _activitiesByPond[pondId] ?? const [];

  List<FishDailySummary> getSummaries(String pondId) =>
      _summariesByPond[pondId] ?? const [];

  List<FishDailySuggestion> getSuggestions(String pondId) =>
      _suggestionsByPond[pondId] ?? const [];

  FishDailySuggestion? getTodaySuggestion(String pondId) {
    final list = _suggestionsByPond[pondId];
    if (list == null || list.isEmpty) return null;
    final now = DateTime.now();
    try {
      return list.firstWhere(
        (s) =>
            s.date.year == now.year &&
            s.date.month == now.month &&
            s.date.day == now.day,
      );
    } catch (_) {
      return list.first;
    }
  }

  void _onAuthChanged(User? user) {
    _cancelAllSubscriptions();
    _activitiesByPond.clear();
    _summariesByPond.clear();
    _suggestionsByPond.clear();
    notifyListeners();
  }

  void _cancelAllSubscriptions() {
    for (final s in _activitySubs.values) {
      s.cancel();
    }
    _activitySubs.clear();
    for (final s in _summarySubs.values) {
      s.cancel();
    }
    _summarySubs.clear();
    for (final s in _suggestionSubs.values) {
      s.cancel();
    }
    _suggestionSubs.clear();
  }

  void bindPond(String pondId) {
    final user = _auth.currentUser;
    if (user == null || pondId.isEmpty) return;

    if (!_activitySubs.containsKey(pondId)) {
      final actQuery = _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .collection(AppConstants.fishPondsCollection)
          .doc(pondId)
          .collection(AppConstants.fishActivitiesCollection)
          .orderBy('scheduledDate');

      _activitySubs[pondId] = actQuery.snapshots().listen((snap) {
        _activitiesByPond[pondId] =
            snap.docs
                .map((d) {
                  try {
                    final m = d.data();
                    m['id'] = d.id;
                    return FishActivity.fromMap(m);
                  } catch (e) {
                    debugPrint('Error parsing fish activity: $e');
                    return null;
                  }
                })
                .whereType<FishActivity>()
                .toList();
        notifyListeners();
      });
    }

    if (!_summarySubs.containsKey(pondId)) {
      final sumQuery = _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .collection(AppConstants.fishPondsCollection)
          .doc(pondId)
          .collection(AppConstants.fishDailySummariesCollection)
          .orderBy('date', descending: true);

      _summarySubs[pondId] = sumQuery.snapshots().listen((snap) {
        _summariesByPond[pondId] =
            snap.docs
                .map((d) {
                  try {
                    final m = d.data();
                    m['id'] = d.id;
                    return FishDailySummary.fromMap(m);
                  } catch (e) {
                    debugPrint('Error parsing fish summary: $e');
                    return null;
                  }
                })
                .whereType<FishDailySummary>()
                .toList();
        notifyListeners();
      });
    }

    if (!_suggestionSubs.containsKey(pondId)) {
      final sugQuery = _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .collection(AppConstants.fishPondsCollection)
          .doc(pondId)
          .collection(AppConstants.fishDailySuggestionsCollection)
          .orderBy('date', descending: true);

      _suggestionSubs[pondId] = sugQuery.snapshots().listen((snap) {
        _suggestionsByPond[pondId] =
            snap.docs
                .map((d) {
                  try {
                    final m = d.data();
                    m['id'] = d.id;
                    return FishDailySuggestion.fromMap(m);
                  } catch (e) {
                    debugPrint('Error parsing fish suggestion: $e');
                    return null;
                  }
                })
                .whereType<FishDailySuggestion>()
                .toList();
        notifyListeners();
      });
    }
  }

  Future<void> toggleActivity(
    String pondId,
    String activityId,
    bool isCompleted,
  ) async {
    final list = _activitiesByPond[pondId];
    if (list != null) {
      final idx = list.indexWhere((a) => a.id == activityId);
      if (idx >= 0) {
        list[idx].isCompleted = isCompleted;
        list[idx].completedAt = isCompleted ? DateTime.now() : null;
        notifyListeners();
      }
    }
    await _sync.toggleFishActivity(pondId, activityId, isCompleted);
  }

  Future<void> addSummary(FishDailySummary summary) async {
    final list = _summariesByPond[summary.fishPondId] ?? [];
    list.insert(0, summary);
    _summariesByPond[summary.fishPondId] = list;
    notifyListeners();

    await _sync.upsertFishSummary(summary);
  }

  Future<void> saveSuggestion(FishDailySuggestion suggestion) async {
    final list = _suggestionsByPond[suggestion.fishPondId] ?? [];
    list.removeWhere(
      (s) =>
          s.date.year == suggestion.date.year &&
          s.date.month == suggestion.date.month &&
          s.date.day == suggestion.date.day,
    );
    list.insert(0, suggestion);
    _suggestionsByPond[suggestion.fishPondId] = list;
    notifyListeners();

    await _sync.upsertFishDailySuggestion(suggestion);
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _cancelAllSubscriptions();
    super.dispose();
  }
}
