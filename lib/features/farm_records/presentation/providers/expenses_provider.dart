import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../data/models/expense.dart';
import '../../../../data/services/expenses_realtime_service.dart';

/// Owns the live list of expenses for the farm records feature.
///
/// All reads come from Cloud Firestore via [ExpensesRealtimeService].
/// There is no local cache — the realtime stream is the single
/// source of truth and the provider mirrors whatever the service
/// publishes.
class ExpensesProvider extends ChangeNotifier {
  ExpensesProvider({ExpensesRealtimeService? realtime})
    : _realtime = realtime ?? ExpensesRealtimeService() {
    _subscribe();
  }

  final ExpensesRealtimeService _realtime;
  StreamSubscription<List<Expense>>? _sub;

  List<Expense> _expenses = const [];
  bool _loading = true;

  List<Expense> get expenses => _expenses;
  bool get isLoading => _loading;

  /// Force a fresh subscription tick from Firestore. Called from the
  /// list screen's `RefreshIndicator` so a pull-to-refresh never
  /// leaves the user staring at stale numbers.
  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _realtime.invalidate();
    _loading = false;
    notifyListeners();
  }

  double get total => _expenses.fold<double>(0, (s, e) => s + e.amount);

  double get monthlyTotal {
    final now = DateTime.now();
    return _expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .fold<double>(0, (s, e) => s + e.amount);
  }

  Map<String, double> get totalsByCategory {
    final out = <String, double>{};
    for (final e in _expenses) {
      out.update(e.category, (v) => v + e.amount, ifAbsent: () => e.amount);
    }
    return out;
  }

  /// Subscribe to the realtime expenses stream. Latest wins — keep
  /// the local list sorted newest-first so the UI is stable across
  /// re-renders.
  void _subscribe() {
    _sub?.cancel();
    _loading = true;
    notifyListeners();
    _sub = _realtime.stream().listen((list) {
      _expenses = [...list]..sort((a, b) => b.date.compareTo(a.date));
      _loading = false;
      notifyListeners();
    });
  }

  Future<void> save(Expense e) async {
    await _realtime.save(e);
    _realtime.invalidate();
  }

  Future<void> remove(String id) async {
    await _realtime.delete(id);
    _realtime.invalidate();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
