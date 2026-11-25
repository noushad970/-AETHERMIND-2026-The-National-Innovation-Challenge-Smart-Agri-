import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';
import '../models/expense.dart';
import 'firestore_sync_service.dart';

/// Real-time expenses service: streams the signed-in user's expenses
/// directly from Cloud Firestore. Mirrors [CropsRealtimeService] so
/// crop + livestock + expenses features share the same lifecycle
/// pattern (auth-aware subscription, error-tolerant, silent offline).
class ExpensesRealtimeService extends ChangeNotifier {
  ExpensesRealtimeService({
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
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _expensesSub;

  String? _uid;
  String? _lastError;
  List<Expense> _lastExpenses = const [];

  /// Latest snapshot of the signed-in user's expenses. Equivalent
  /// to listening to [stream] but synchronous.
  List<Expense> get snapshot => List<Expense>.unmodifiable(_lastExpenses);

  String? get lastError => _lastError;
  void clearError() {
    if (_lastError == null) return;
    _lastError = null;
    notifyListeners();
  }

  Stream<List<Expense>> stream() async* {
    yield _lastExpenses;
    yield* _controller.stream;
  }

  final StreamController<List<Expense>> _controller =
      StreamController<List<Expense>>.broadcast();

  void _publish(List<Expense> expenses) {
    _lastExpenses = expenses;
    if (!_controller.isClosed) _controller.add(expenses);
    notifyListeners();
  }

  void _onAuthChanged(String? uid) {
    if (_uid == uid) return;
    _uid = uid;
    _expensesSub?.cancel();
    _expensesSub = null;
    if (uid == null) {
      _publish(const []);
      return;
    }

    final col = _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection(AppConstants.expensesCollection);
    _bootstrap(col);
    _expensesSub = col.snapshots().listen(
      (snap) {
        _lastError = null;
        _publish(_fromSnapshot(snap));
      },
      onError: (Object e, StackTrace st) {
        developer.log(
          'Expenses stream failed',
          name: 'ExpensesRealtimeService',
          error: e,
          stackTrace: st,
        );
        _lastError = 'Realtime expense sync failed: $e';
        notifyListeners();
      },
    );
  }

  Future<void> _bootstrap(CollectionReference<Map<String, dynamic>> col) async {
    try {
      final snap = await col.get();
      _publish(_fromSnapshot(snap));
    } catch (e, st) {
      developer.log(
        'Expenses bootstrap get failed',
        name: 'ExpensesRealtimeService',
        error: e,
        stackTrace: st,
      );
    }
  }

  List<Expense> _fromSnapshot(QuerySnapshot<Map<String, dynamic>> snap) {
    final out = <Expense>[];
    for (final doc in snap.docs) {
      final data = doc.data();
      data['id'] = doc.id;
      try {
        out.add(_expenseFromMap(data));
      } catch (e) {
        developer.log(
          'Skipping malformed expense ${doc.id}: $e',
          name: 'ExpensesRealtimeService',
        );
      }
    }
    out.sort((a, b) => b.date.compareTo(a.date));
    return out;
  }

  Expense _expenseFromMap(Map<String, dynamic> m) => Expense(
    id: (m['id'] ?? '').toString(),
    cropId: (m['cropId'] ?? '').toString(),
    category: (m['category'] ?? '').toString(),
    amount: _toDouble(m['amount']),
    date: _parseDate(m['date']) ?? DateTime.now(),
    description: (m['description'] ?? '').toString(),
  );

  DateTime? _parseDate(Object? v) {
    if (v == null) return null;
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

  double _toDouble(Object? v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  /// Force a re-publish of the latest snapshot. Called by [save] /
  /// [delete] so the UI updates without waiting for the next server
  /// snapshot.
  void invalidate() {
    if (_lastExpenses.isEmpty && _uid == null) return;
    _publish(_lastExpenses);
  }

  Future<void> save(Expense expense) async {
    if (_uid == null) return;
    await _sync.upsertExpense(expense);
    _upsertMirror(expense);
    _publish(_lastExpenses);
  }

  Future<void> delete(String id) async {
    if (_uid == null) return;
    await _sync.deleteExpense(id);
    _lastExpenses = _lastExpenses
        .where((e) => e.id != id)
        .toList(growable: false);
    _publish(_lastExpenses);
  }

  /// Insert/overwrite [expense] in the in-memory mirror, keeping the
  /// same newest-date-first order the snapshot decoder uses.
  void _upsertMirror(Expense expense) {
    final idx = _lastExpenses.indexWhere((e) => e.id == expense.id);
    final next = [..._lastExpenses];
    if (idx == -1) {
      next.add(expense);
    } else {
      next[idx] = expense;
    }
    next.sort((a, b) => b.date.compareTo(a.date));
    _lastExpenses = next;
  }

  @override
  void dispose() {
    _expensesSub?.cancel();
    _authSub?.cancel();
    _controller.close();
    super.dispose();
  }
}
