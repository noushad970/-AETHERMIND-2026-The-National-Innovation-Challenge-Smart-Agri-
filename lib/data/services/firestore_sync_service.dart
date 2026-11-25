import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/constants/app_constants.dart';
import '../models/animal.dart';
import '../models/chat_message.dart';
import '../models/crop.dart';
import '../models/daily_suggestion.dart';
import '../models/disease_result.dart';
import '../models/expense.dart';
import '../models/fish_activity.dart';
import '../models/fish_daily_suggestion.dart';
import '../models/fish_daily_summary.dart';
import '../models/fish_pond.dart';
import '../models/livestock_daily_summary.dart';
import '../models/livestock_daily_suggestion.dart';
import '../models/market_price.dart';

/// Mirrors user-owned data (crops, expenses, chat, disease scans) to
/// Cloud Firestore under per-user subcollections.
///
/// Schema:
///   users/{uid}                            -> profile (uid, email, displayName, updatedAt)
///   users/{uid}/crops/{cropId}             -> Crop
///   users/{uid}/expenses/{expenseId}       -> Expense
///   users/{uid}/chatThreads/{threadId}     -> { id, title, updatedAt, lastMessageAt }
///   users/{uid}/chatThreads/{threadId}/messages/{messageId}  -> ChatMessage
///   users/{uid}/diseaseScans/{scanId}      -> DiseaseResult (toJson) + meta
///   users/{uid}/livestock/{livestockId}    -> Livestock
///   users/{uid}/livestock/{livestockId}/dailySummaries/{dateKey} -> LivestockDailySummary
///   users/{uid}/livestock/{livestockId}/dailySuggestions/{dateKey} -> LivestockDailySuggestion
///
/// All writes are fire-and-forget on the caller side so the UI stays
/// responsive. Errors are logged via [lastSyncError] / [syncErrors] so
/// the UI can surface banners instead of having them silently swallowed
/// by `unawaited`. Firestore is the durable source of truth; the
/// per-feature realtime services (e.g. CropsRealtimeService) stream
/// straight from Firestore so the UI never depends on a local cache.
class FirestoreSyncService {
  FirestoreSyncService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  // In-memory cache of the most recently known user id so a sign-out
  // followed by an immediate write doesn't try to push to a stale uid.
  String? _lastKnownUid;

  /// Latest sync error message, or null when the last write succeeded /
  /// there has been no write since sign-in. Surfaced to the UI so the
  /// user can see permission-denied / network errors instead of having
  /// them silently swallowed by `unawaited`.
  final ValueNotifier<String?> lastSyncError = ValueNotifier<String?>(null);

  /// Stream of sync error messages (one entry per failed write). The UI
  /// can listen to this to show banners or toasts without rebuilding on
  /// every state change.
  Stream<String> get syncErrors => _errorController.stream;
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  /// Human-friendly label for the most recent failing operation. Used
  /// in conjunction with [lastSyncError] by the home-screen banner.
  final ValueNotifier<String> lastSyncOp = ValueNotifier<String>('');

  /// Records a sync error so the UI can show it. Errors are also logged
  /// via [developer.log] for the console / DevTools view.
  void _recordError(String op, Object error, [StackTrace? stack]) {
    final msg = _humaniseError(error);
    developer.log(
      'Firestore $op failed: $msg',
      name: 'FirestoreSyncService',
      error: error,
      stackTrace: stack,
    );
    lastSyncOp.value = op;
    lastSyncError.value = msg;
    if (!_errorController.isClosed) _errorController.add(msg);
  }

  /// Translates the wide range of Firestore / Firebase exceptions into
  /// a short, user-readable message. Falls back to `toString()` for
  /// anything we don't recognise.
  String _humaniseError(Object error) {
    final s = error.toString();
    if (s.contains('permission-denied') || s.contains('PERMISSION_DENIED')) {
      return 'Cloud sync blocked: Firestore security rules deny this '
          'write. Deploy firestore.rules to fix it.';
    }
    if (s.contains('unauthenticated') || s.contains('UNAUTHENTICATED')) {
      return 'Cloud sync blocked: you are signed out.';
    }
    if (s.contains('unavailable') ||
        s.contains('UNAVAILABLE') ||
        s.contains('network') ||
        s.contains('SocketException')) {
      return 'Cloud sync failed: network unavailable. Will retry '
          'automatically when online.';
    }
    if (s.contains('not-found') || s.contains('NOT_FOUND')) {
      return 'Cloud sync failed: document not found on the server.';
    }
    if (s.contains('already-exists') || s.contains('ALREADY_EXISTS')) {
      return 'Cloud sync skipped: a record with this id already exists.';
    }
    return 'Cloud sync failed: $s';
  }

  /// Clears the last error (e.g. after the user reads the banner).
  void clearSyncError() {
    lastSyncError.value = null;
    lastSyncOp.value = '';
  }

  String? get _uid => _auth.currentUser?.uid ?? _lastKnownUid;

  /// True when there is a real, signed-in user that we can target with
  /// Firestore writes. Repositories use this to decide between an
  /// immediate background sync vs. queueing the write until sign-in.
  bool get isReady {
    final u = _auth.currentUser;
    return u != null && !u.isAnonymous;
  }

  /// The current signed-in user's uid, or null if signed out. Used by
  /// the crop repository to retag local-only crops on first sign-in.
  String? get currentUid => _auth.currentUser?.uid;

  /// Cache the uid before sign-out so background sync calls that race
  /// with the auth state change still hit the right user.
  void rememberCurrentUser() {
    final u = _auth.currentUser;
    if (u != null) _lastKnownUid = u.uid;
  }

  /// Forget the cached uid after sign-out completes.
  void clearCachedUser() {
    _lastKnownUid = null;
  }

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection(AppConstants.usersCollection).doc(uid);

  CollectionReference<Map<String, dynamic>> _crops(String uid) =>
      _userDoc(uid).collection(AppConstants.cropsCollection);

  CollectionReference<Map<String, dynamic>> _expenses(String uid) =>
      _userDoc(uid).collection(AppConstants.expensesCollection);

  CollectionReference<Map<String, dynamic>> _threads(String uid) =>
      _userDoc(uid).collection(AppConstants.chatThreadsCollection);

  CollectionReference<Map<String, dynamic>> _scans(String uid) =>
      _userDoc(uid).collection(AppConstants.diseaseScansCollection);

  CollectionReference<Map<String, dynamic>> _livestock(String uid) =>
      _userDoc(uid).collection(AppConstants.livestockCollection);

  CollectionReference<Map<String, dynamic>> _dailySummaries(
    String uid,
    String livestockId,
  ) => _livestock(
    uid,
  ).doc(livestockId).collection(AppConstants.livestockDailySummariesCollection);

  CollectionReference<Map<String, dynamic>> _livestockDailySuggestions(
    String uid,
    String livestockId,
  ) => _livestock(uid)
      .doc(livestockId)
      .collection(AppConstants.livestockDailySuggestionsCollection);

  CollectionReference<Map<String, dynamic>> _livestockActivities(
    String uid,
    String animalId,
  ) => _livestock(
    uid,
  ).doc(animalId).collection(AppConstants.livestockActivitiesCollection);

  CollectionReference<Map<String, dynamic>> _livestockSummaries(
    String uid,
    String animalId,
  ) => _livestock(
    uid,
  ).doc(animalId).collection(AppConstants.livestockDailySummariesCollection);

  CollectionReference<Map<String, dynamic>> _livestockSuggestions(
    String uid,
    String animalId,
  ) => _livestock(
    uid,
  ).doc(animalId).collection(AppConstants.livestockDailySuggestionsCollection);

  CollectionReference<Map<String, dynamic>> _fishPonds(String uid) =>
      _userDoc(uid).collection(AppConstants.fishPondsCollection);

  CollectionReference<Map<String, dynamic>> _fishActivities(
    String uid,
    String pondId,
  ) => _fishPonds(
    uid,
  ).doc(pondId).collection(AppConstants.fishActivitiesCollection);

  CollectionReference<Map<String, dynamic>> _fishSummaries(
    String uid,
    String pondId,
  ) => _fishPonds(
    uid,
  ).doc(pondId).collection(AppConstants.fishDailySummariesCollection);

  CollectionReference<Map<String, dynamic>> _fishSuggestions(
    String uid,
    String pondId,
  ) => _fishPonds(
    uid,
  ).doc(pondId).collection(AppConstants.fishDailySuggestionsCollection);

  CollectionReference<Map<String, dynamic>> _marketPrices(String uid) =>
      _userDoc(uid).collection(AppConstants.marketPricesCollection);

  Future<void> upsertUserProfile({String? email, String? displayName}) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _userDoc(uid).set({
        'uid': uid,
        'email': email ?? _auth.currentUser?.email,
        'displayName': displayName ?? _auth.currentUser?.displayName,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e, st) {
      _recordError('upsertUserProfile', e, st);
    }
  }

  // --- Crops ---------------------------------------------------------------

  Future<void> upsertCrop(Crop crop) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _crops(uid).doc(crop.id).set({
        ...crop.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e, st) {
      _recordError('upsertCrop', e, st);
    }
  }

  Future<void> deleteCrop(String id) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _crops(uid).doc(id).delete();
    } catch (e, st) {
      _recordError('deleteCrop', e, st);
    }
  }

  // --- Expenses ------------------------------------------------------------

  Future<void> upsertExpense(Expense expense) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _expenses(uid).doc(expense.id).set({
        ...expense.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e, st) {
      _recordError('upsertExpense', e, st);
    }
  }

  Future<void> deleteExpense(String id) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _expenses(uid).doc(id).delete();
    } catch (e, st) {
      _recordError('deleteExpense', e, st);
    }
  }

  // --- Livestock -----------------------------------------------------------

  Future<void> upsertLivestock(Animal livestock) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _livestock(uid).doc(livestock.id).set({
        ...livestock.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e, st) {
      _recordError('upsertLivestock', e, st);
    }
  }

  Future<void> toggleLivestockActivity({
    required Animal animal,
    required LivestockActivity activity,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _livestockActivities(uid, animal.id).doc(activity.id).set({
        ...activity.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e, st) {
      _recordError('toggleLivestockActivity', e, st);
    }
  }

  Future<void> deleteLivestock(String id) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _livestock(uid).doc(id).delete();
    } catch (e, st) {
      _recordError('deleteLivestock', e, st);
    }
  }

  Future<void> upsertLivestockDailySummary({
    required String livestockId,
    required LivestockDailySummary summary,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _dailySummaries(uid, livestockId).doc(summary.dateKey).set({
        ...summary.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e, st) {
      _recordError('upsertLivestockDailySummary', e, st);
    }
  }

  Future<void> deleteLivestockDailySummary({
    required String livestockId,
    required String dateKey,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _dailySummaries(uid, livestockId).doc(dateKey).delete();
    } catch (e, st) {
      _recordError('deleteLivestockDailySummary', e, st);
    }
  }

  Future<void> upsertLivestockDailySuggestion({
    required String livestockId,
    required LivestockDailySuggestion suggestion,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _livestockDailySuggestions(
        uid,
        livestockId,
      ).doc(suggestion.dateKey).set({
        ...suggestion.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e, st) {
      _recordError('upsertLivestockDailySuggestion', e, st);
    }
  }

  Future<void> deleteLivestockDailySuggestion({
    required String livestockId,
    required String dateKey,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _livestockDailySuggestions(uid, livestockId).doc(dateKey).delete();
    } catch (e, st) {
      _recordError('deleteLivestockDailySuggestion', e, st);
    }
  }

  Future<void> upsertLivestockSummary(LivestockDailySummary s) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _livestockSummaries(uid, s.animalId).doc(s.dateKey).set({
        ...s.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e, st) {
      _recordError('upsertLivestockSummary', e, st);
    }
  }

  Future<void> upsertLivestockSuggestion(LivestockDailySuggestion s) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _livestockSuggestions(uid, s.animalId).doc(s.dateKey).set({
        ...s.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      developer.log(
        'Firestore upsertLivestockSuggestion failed: $e',
        name: 'FirestoreSyncService',
        error: e,
      );
    }
  }

  // --- Chat ----------------------------------------------------------------

  Future<void> upsertChatMessage({
    required String threadId,
    required ChatMessage message,
    String? threadTitle,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final threadRef = _threads(uid).doc(threadId);
      final batch = _firestore.batch();
      batch.set(threadRef, {
        'id': threadId,
        'title': threadTitle ?? threadId,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessagePreview': message.content.length > 120
            ? '${message.content.substring(0, 120)}…'
            : message.content,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      batch.set(threadRef.collection('messages').doc(message.id), {
        ...message.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await batch.commit();
    } catch (e) {
      developer.log(
        'Firestore upsertChatMessage failed: $e',
        name: 'FirestoreSyncService',
        error: e,
      );
    }
  }

  Future<void> deleteChatThread(String threadId) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      // Pull all messages in the thread, delete in a single batch.
      final msgs = await _threads(
        uid,
      ).doc(threadId).collection('messages').get();
      final batch = _firestore.batch();
      for (final m in msgs.docs) {
        batch.delete(m.reference);
      }
      batch.delete(_threads(uid).doc(threadId));
      await batch.commit();
    } catch (e) {
      developer.log(
        'Firestore deleteChatThread failed: $e',
        name: 'FirestoreSyncService',
        error: e,
      );
    }
  }

  // --- Disease scans -------------------------------------------------------

  Future<void> upsertDiseaseScan({
    required String id,
    required DiseaseResult result,
    String? imagePath,
    String? imageStoragePath,
    DateTime? scannedAt,
    bool fromOfflineModel = true,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _scans(uid).doc(id).set({
        'id': id,
        'scannedAt': scannedAt ?? DateTime.now(),
        'imagePath': imagePath,
        'imageStoragePath': imageStoragePath,
        'fromOfflineModel': fromOfflineModel,
        'result': result.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      developer.log(
        'Firestore upsertDiseaseScan failed: $e',
        name: 'FirestoreSyncService',
        error: e,
      );
    }
  }

  Future<void> deleteDiseaseScan(String id) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _scans(uid).doc(id).delete();
    } catch (e) {
      developer.log(
        'Firestore deleteDiseaseScan failed: $e',
        name: 'FirestoreSyncService',
        error: e,
      );
    }
  }

  // --- Daily crop suggestions ---------------------------------------------

  /// Subcollection path:
  ///   users/{uid}/crops/{cropId}/dailySuggestions/{dateKey}
  ///
  /// Because the doc id is the local date string, every crop has at
  /// most one suggestion per day. Re-generating overwrites the same
  /// document instead of accumulating history.
  CollectionReference<Map<String, dynamic>> _dailySuggestions(
    String uid,
    String cropId,
  ) {
    return _crops(
      uid,
    ).doc(cropId).collection(AppConstants.dailySuggestionsCollection);
  }

  Future<void> upsertDailySuggestion(DailySuggestion suggestion) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _dailySuggestions(
        uid,
        suggestion.cropId,
      ).doc(suggestion.dateKey).set({
        ...suggestion.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      developer.log(
        'Firestore upsertDailySuggestion failed: $e',
        name: 'FirestoreSyncService',
        error: e,
      );
    }
  }

  Future<void> deleteDailySuggestion({
    required String cropId,
    required String dateKey,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _dailySuggestions(uid, cropId).doc(dateKey).delete();
    } catch (e) {
      developer.log(
        'Firestore deleteDailySuggestion failed: $e',
        name: 'FirestoreSyncService',
        error: e,
      );
    }
  }

  // --- Market prices -------------------------------------------------------

  /// Persist a single market-price record keyed by its [dateKey]
  /// (`YYYY-MM-DD`). The doc id is the same as the record id so that
  /// upserting the same day's data overwrites cleanly.
  Future<void> upsertMarketPrice(MarketPrice price) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _marketPrices(uid).doc(price.id).set(price.toMap());
    } catch (e, st) {
      _recordError('upsertMarketPrice', e, st);
    }
  }

  /// Bulk upsert a list of market-price records. Used by the daily
  /// scrape so the whole market goes in one batched request.
  Future<void> upsertMarketPrices(List<MarketPrice> prices) async {
    final uid = _uid;
    if (uid == null) return;
    if (prices.isEmpty) return;
    try {
      final batch = _firestore.batch();
      for (final p in prices) {
        batch.set(_marketPrices(uid).doc(p.id), p.toMap());
      }
      await batch.commit();
    } catch (e, st) {
      _recordError('upsertMarketPrices', e, st);
    }
  }

  /// Delete a single market-price record. No-op when the user is
  /// signed out or Firestore returns a not-found.
  Future<void> deleteMarketPrice(String id) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _marketPrices(uid).doc(id).delete();
    } catch (e, st) {
      _recordError('deleteMarketPrice', e, st);
    }
  }

  /// Delete every market-price record for [market]. Used when the
  /// scraper returns a fresh batch and the old cache should be wiped
  /// first so the UI never shows stale numbers next to live ones.
  Future<void> deleteMarketPricesForMarket(String market) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final snap = await _marketPrices(uid).get();
      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        final data = doc.data();
        if (data['market'] == market) {
          batch.delete(doc.reference);
        }
      }
      await batch.commit();
    } catch (e, st) {
      _recordError('deleteMarketPricesForMarket', e, st);
    }
  }

  // --- Fish Ponds & Aquaculture Sync -----------------------------------------

  Future<void> upsertFishPond(FishPond pond) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final data = pond.toMap();
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _fishPonds(uid).doc(pond.id).set(data, SetOptions(merge: true));

      if (pond.activities.isNotEmpty) {
        final batch = _firestore.batch();
        for (final act in pond.activities) {
          final actRef = _fishActivities(uid, pond.id).doc(act.id);
          batch.set(actRef, act.toMap(), SetOptions(merge: true));
        }
        await batch.commit();
      }
    } catch (e, st) {
      _recordError('upsertFishPond', e, st);
    }
  }

  Future<void> deleteFishPond(String pondId) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _fishPonds(uid).doc(pondId).delete();
    } catch (e, st) {
      _recordError('deleteFishPond', e, st);
    }
  }

  Future<void> upsertFishActivity(FishActivity activity) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _fishActivities(uid, activity.fishPondId).doc(activity.id).set(
        activity.toMap(),
        SetOptions(merge: true),
      );
    } catch (e, st) {
      _recordError('upsertFishActivity', e, st);
    }
  }

  Future<void> toggleFishActivity(
    String pondId,
    String activityId,
    bool isCompleted,
  ) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _fishActivities(uid, pondId).doc(activityId).set({
        'isCompleted': isCompleted,
        'completedAt': isCompleted ? DateTime.now().toIso8601String() : null,
      }, SetOptions(merge: true));
    } catch (e, st) {
      _recordError('toggleFishActivity', e, st);
    }
  }

  Future<void> deleteFishActivity(String pondId, String activityId) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _fishActivities(uid, pondId).doc(activityId).delete();
    } catch (e, st) {
      _recordError('deleteFishActivity', e, st);
    }
  }

  Future<void> upsertFishSummary(FishDailySummary summary) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final dateKey =
          '${summary.date.year}-${summary.date.month.toString().padLeft(2, '0')}-${summary.date.day.toString().padLeft(2, '0')}';
      await _fishSummaries(uid, summary.fishPondId).doc(dateKey).set(
        summary.toMap(),
        SetOptions(merge: true),
      );
    } catch (e, st) {
      _recordError('upsertFishSummary', e, st);
    }
  }

  Future<void> deleteFishSummary(String pondId, String summaryId) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _fishSummaries(uid, pondId).doc(summaryId).delete();
    } catch (e, st) {
      _recordError('deleteFishSummary', e, st);
    }
  }

  Future<void> upsertFishDailySuggestion(FishDailySuggestion suggestion) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final dateKey =
          '${suggestion.date.year}-${suggestion.date.month.toString().padLeft(2, '0')}-${suggestion.date.day.toString().padLeft(2, '0')}';
      await _fishSuggestions(uid, suggestion.fishPondId).doc(dateKey).set(
        suggestion.toMap(),
        SetOptions(merge: true),
      );
    } catch (e, st) {
      _recordError('upsertFishDailySuggestion', e, st);
    }
  }

  Future<void> deleteFishDailySuggestion(
    String pondId,
    String suggestionId,
  ) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _fishSuggestions(uid, pondId).doc(suggestionId).delete();
    } catch (e, st) {
      _recordError('deleteFishDailySuggestion', e, st);
    }
  }

  // --- Hydration (pull from Firestore on login) ----------------------------

  /// Fetches every document in each per-user subcollection and returns
  /// the raw maps. The caller (e.g. login flow) decides how to
  /// prime the in-memory caches from them.
  ///
  /// Returns empty maps when the user is signed out or Firestore
  /// errors — never throws, so a transient offline state never blocks
  /// the local app from working.
  Future<HydrationResult> pullAll() async {
    final uid = _uid;
    if (uid == null) return HydrationResult.empty();
    try {
      final results = await Future.wait([
        _crops(uid).get(),
        _expenses(uid).get(),
        _threads(uid).get(),
        _scans(uid).get(),
        _livestock(uid).get(),
        _marketPrices(uid).get(),
        _fishPonds(uid).get(),
      ]);
      final crops = <String, Map<String, dynamic>>{
        for (final d in results[0].docs) d.id: d.data(),
      };
      final expenses = <String, Map<String, dynamic>>{
        for (final d in results[1].docs) d.id: d.data(),
      };
      final threads = <String, Map<String, dynamic>>{
        for (final d in results[2].docs) d.id: d.data(),
      };
      final scans = <String, Map<String, dynamic>>{
        for (final d in results[3].docs) d.id: d.data(),
      };
      final livestock = <String, Map<String, dynamic>>{
        for (final d in results[4].docs) d.id: d.data(),
      };
      final marketPrices = <String, Map<String, dynamic>>{
        for (final d in results[5].docs) d.id: d.data(),
      };
      final fishPonds = <String, Map<String, dynamic>>{
        for (final d in results[6].docs) d.id: d.data(),
      };

      // Pull messages for every thread.
      final messagesByThread = <String, List<Map<String, dynamic>>>{};
      await Future.wait(
        threads.keys.map((threadId) async {
          final msgs = await _threads(
            uid,
          ).doc(threadId).collection('messages').get();
          messagesByThread[threadId] = msgs.docs.map((d) => d.data()).toList();
        }),
      );

      // Pull daily suggestions for every crop.
      final dailySuggestionsByCrop = <String, List<Map<String, dynamic>>>{};
      await Future.wait(
        crops.keys.map((cropId) async {
          final ds = await _dailySuggestions(uid, cropId).get();
          if (ds.docs.isEmpty) return;
          dailySuggestionsByCrop[cropId] = ds.docs
              .map((d) => d.data())
              .toList(growable: false);
        }),
      );

      // Pull livestock activities, summaries, and daily suggestions.
      final livestockActivitiesByAnimal =
          <String, List<Map<String, dynamic>>>{};
      final livestockSummariesByAnimal = <String, List<Map<String, dynamic>>>{};
      final livestockSuggestionsByAnimal =
          <String, List<Map<String, dynamic>>>{};
      await Future.wait(
        livestock.keys.map((animalId) async {
          final acts = await _livestockActivities(uid, animalId).get();
          livestockActivitiesByAnimal[animalId] = acts.docs
              .map((d) => d.data())
              .toList(growable: false);
          final sums = await _livestockSummaries(uid, animalId).get();
          livestockSummariesByAnimal[animalId] = sums.docs
              .map((d) => d.data())
              .toList(growable: false);
          final sugs = await _livestockSuggestions(uid, animalId).get();
          livestockSuggestionsByAnimal[animalId] = sugs.docs
              .map((d) => d.data())
              .toList(growable: false);
        }),
      );

      // Pull fish activities, summaries, and daily suggestions.
      final fishActivitiesByPond = <String, List<Map<String, dynamic>>>{};
      final fishSummariesByPond = <String, List<Map<String, dynamic>>>{};
      final fishSuggestionsByPond = <String, List<Map<String, dynamic>>>{};
      await Future.wait(
        fishPonds.keys.map((pondId) async {
          final acts = await _fishActivities(uid, pondId).get();
          fishActivitiesByPond[pondId] = acts.docs
              .map((d) => d.data())
              .toList(growable: false);
          final sums = await _fishSummaries(uid, pondId).get();
          fishSummariesByPond[pondId] = sums.docs
              .map((d) => d.data())
              .toList(growable: false);
          final sugs = await _fishSuggestions(uid, pondId).get();
          fishSuggestionsByPond[pondId] = sugs.docs
              .map((d) => d.data())
              .toList(growable: false);
        }),
      );

      return HydrationResult(
        crops: crops,
        expenses: expenses,
        threads: threads,
        scans: scans,
        messagesByThread: messagesByThread,
        dailySuggestionsByCrop: dailySuggestionsByCrop,
        livestock: livestock,
        livestockActivitiesByAnimal: livestockActivitiesByAnimal,
        livestockSummariesByAnimal: livestockSummariesByAnimal,
        livestockSuggestionsByAnimal: livestockSuggestionsByAnimal,
        fishPonds: fishPonds,
        fishActivitiesByPond: fishActivitiesByPond,
        fishSummariesByPond: fishSummariesByPond,
        fishSuggestionsByPond: fishSuggestionsByPond,
        marketPrices: marketPrices,
      );
    } catch (e) {
      developer.log(
        'Firestore pullAll failed: $e',
        name: 'FirestoreSyncService',
        error: e,
      );
      return HydrationResult.empty();
    }
  }
}

/// Plain-old-data result of a [FirestoreSyncService.pullAll] call.
class HydrationResult {
  HydrationResult({
    required this.crops,
    required this.expenses,
    required this.threads,
    required this.scans,
    required this.messagesByThread,
    this.dailySuggestionsByCrop = const {},
    this.dailySummariesByLivestock = const {},
    this.dailySuggestionsByLivestock = const {},
    required this.livestock,
    required this.livestockActivitiesByAnimal,
    required this.livestockSummariesByAnimal,
    required this.livestockSuggestionsByAnimal,
    this.fishPonds = const {},
    this.fishActivitiesByPond = const {},
    this.fishSummariesByPond = const {},
    this.fishSuggestionsByPond = const {},
    this.marketPrices = const {},
  });

  factory HydrationResult.empty() => HydrationResult(
    crops: const {},
    expenses: const {},
    threads: const {},
    scans: const {},
    messagesByThread: const {},
    livestock: const {},
    livestockActivitiesByAnimal: const {},
    livestockSummariesByAnimal: const {},
    livestockSuggestionsByAnimal: const {},
    fishPonds: const {},
    fishActivitiesByPond: const {},
    fishSummariesByPond: const {},
    fishSuggestionsByPond: const {},
    marketPrices: const {},
  );

  final Map<String, Map<String, dynamic>> crops;
  final Map<String, Map<String, dynamic>> expenses;
  final Map<String, Map<String, dynamic>> threads;
  final Map<String, Map<String, dynamic>> scans;
  final Map<String, List<Map<String, dynamic>>> messagesByThread;

  /// Per-crop list of daily suggestions pulled from Firestore.
  final Map<String, List<Map<String, dynamic>>> dailySuggestionsByCrop;

  /// Per-livestock list of daily summaries pulled from Firestore.
  final Map<String, List<Map<String, dynamic>>> dailySummariesByLivestock;

  /// Per-livestock list of daily suggestions pulled from Firestore.
  final Map<String, List<Map<String, dynamic>>> dailySuggestionsByLivestock;

  final Map<String, Map<String, dynamic>> livestock;
  final Map<String, List<Map<String, dynamic>>> livestockActivitiesByAnimal;
  final Map<String, List<Map<String, dynamic>>> livestockSummariesByAnimal;
  final Map<String, List<Map<String, dynamic>>> livestockSuggestionsByAnimal;

  final Map<String, Map<String, dynamic>> fishPonds;
  final Map<String, List<Map<String, dynamic>>> fishActivitiesByPond;
  final Map<String, List<Map<String, dynamic>>> fishSummariesByPond;
  final Map<String, List<Map<String, dynamic>>> fishSuggestionsByPond;

  /// Per-day market price records keyed by dateKey (YYYY-MM-DD).
  final Map<String, Map<String, dynamic>> marketPrices;

  bool get isEmpty =>
      crops.isEmpty &&
      expenses.isEmpty &&
      threads.isEmpty &&
      scans.isEmpty &&
      messagesByThread.isEmpty &&
      dailySuggestionsByCrop.isEmpty &&
      dailySummariesByLivestock.isEmpty &&
      dailySuggestionsByLivestock.isEmpty &&
      livestock.isEmpty &&
      livestockActivitiesByAnimal.isEmpty &&
      livestockSummariesByAnimal.isEmpty &&
      livestockSuggestionsByAnimal.isEmpty &&
      fishPonds.isEmpty &&
      fishActivitiesByPond.isEmpty &&
      fishSummariesByPond.isEmpty &&
      fishSuggestionsByPond.isEmpty &&
      marketPrices.isEmpty;
}
