import '../models/fish_daily_suggestion.dart';
import '../services/fish_children_service.dart';

/// Repository for [FishDailySuggestion] entities.
class FishDailySuggestionRepository {
  FishDailySuggestionRepository({FishChildrenService? svc})
    : _svc = svc ?? FishChildrenService();

  final FishChildrenService _svc;

  FishDailySuggestion? todayFor(String pondId) =>
      _svc.getTodaySuggestion(pondId);

  List<FishDailySuggestion> allFor(String pondId) => _svc.getSuggestions(pondId);

  Future<void> save(FishDailySuggestion suggestion) async {
    await _svc.saveSuggestion(suggestion);
  }
}
