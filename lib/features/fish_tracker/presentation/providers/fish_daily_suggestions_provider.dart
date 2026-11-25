import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

import '../../../../data/models/fish_daily_suggestion.dart';
import '../../../../data/models/fish_daily_summary.dart';
import '../../../../data/models/fish_pond.dart';
import '../../../../data/repositories/fish_daily_suggestion_repository.dart';
import '../../../../data/services/fish_children_service.dart';
import '../../../../data/services/gemini_service.dart';

class FishDailySuggestionsProvider extends ChangeNotifier {
  FishDailySuggestionsProvider({
    FishDailySuggestionRepository? repository,
    GeminiService? gemini,
    FishChildrenService? realtime,
  }) : _repo = repository ?? FishDailySuggestionRepository(),
       _gemini = gemini ?? GeminiService(),
       _realtime = realtime ?? FishChildrenService() {
    _realtime.addListener(_onRealtimeChanged);
  }

  final FishDailySuggestionRepository _repo;
  final GeminiService _gemini;
  final FishChildrenService _realtime;

  final Map<String, FishDailySuggestion> _byPond = {};
  final Map<String, bool> _loading = {};
  final Map<String, String> _errors = {};

  FishDailySuggestion? suggestionFor(String pondId) => _byPond[pondId];
  bool isLoading(String pondId) => _loading[pondId] ?? false;
  String? errorFor(String pondId) => _errors[pondId];

  void primeFromCache(String pondId) {
    if (_byPond.containsKey(pondId)) return;
    final today = _repo.todayFor(pondId);
    if (today != null) {
      _byPond[pondId] = today;
      notifyListeners();
    }
  }

  bool hasFreshTodayRecord(String pondId) {
    final s = _byPond[pondId];
    if (s == null) return false;
    final now = DateTime.now();
    return s.date.year == now.year &&
        s.date.month == now.month &&
        s.date.day == now.day;
  }

  Future<void> ensureToday(FishPond pond, FishDailySummary? summary) async {
    final today = _repo.todayFor(pond.id);
    if (today != null) {
      _byPond[pond.id] = today;
      _errors.remove(pond.id);
      notifyListeners();
      return;
    }
    await refreshFor(pond, summary);
  }

  Future<void> refreshFor(FishPond pond, FishDailySummary? summary) async {
    _loading[pond.id] = true;
    _errors.remove(pond.id);
    notifyListeners();

    final now = DateTime.now();
    FishDailyAdvice advice;
    String source = 'gemini-3.5-flash-lite';
    try {
      advice = await _gemini.getFishGuidance(
        pond: pond,
        summary: summary,
      );
      source = advice.source;
    } catch (e) {
      developer.log(
        'Gemini fish guidance failed: $e',
        name: 'FishDailySuggestionsProvider',
        error: e,
      );
      advice = _gemini.buildOfflineFishGuidance(
        pond: pond,
        summary: summary,
      );
      source = advice.source;
      _errors[pond.id] = 'Showing offline guidance. Will retry on next refresh.';
    }

    final suggestion = FishDailySuggestion(
      id: '${pond.id}_${now.year}_${now.month}_${now.day}',
      fishPondId: pond.id,
      date: now,
      feedingGuidanceBn: advice.guidanceBn,
      feedingGuidanceEn: advice.guidanceEn,
      oxygenAerationAdviceBn: advice.oxygenAerationAdviceBn,
      oxygenAerationAdviceEn: advice.oxygenAerationAdviceEn,
      waterQualityTipsBn: advice.waterQualityTipsBn,
      waterQualityTipsEn: advice.waterQualityTipsEn,
      doItems: advice.doItems,
      dontItems: advice.dontItems,
      source: source,
      generatedAt: now,
    );

    await _repo.save(suggestion);
    _byPond[pond.id] = suggestion;
    _loading[pond.id] = false;
    notifyListeners();
  }

  void _onRealtimeChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _realtime.removeListener(_onRealtimeChanged);
    super.dispose();
  }
}
