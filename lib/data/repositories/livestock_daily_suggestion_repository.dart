import '../models/livestock_daily_suggestion.dart';
import '../services/livestock_children_service.dart';

/// Repository for [LivestockDailySuggestion] entities. Mirrors
/// [DailySuggestionRepository]: at most one suggestion per
/// `animalId|<YYYY-MM-DD>`, overwrite on save, Firestore mirror.
///
/// Reads come from the [LivestockChildrenService] Firestore stream;
/// writes go through the same service.
class LivestockDailySuggestionRepository {
  LivestockDailySuggestionRepository({LivestockChildrenService? svc})
    : _svc = svc ?? LivestockChildrenService();

  final LivestockChildrenService _svc;

  LivestockDailySuggestion? todayFor(String animalId) {
    final dateKey = LivestockDailySuggestion.dateKeyFor(DateTime.now());
    return _svc
        .suggestionsFor(animalId)
        .where((s) => s.dateKey == dateKey)
        .cast<LivestockDailySuggestion?>()
        .firstWhere((_) => true, orElse: () => null);
  }

  LivestockDailySuggestion? latestFor(String animalId) =>
      _svc.latestSuggestionFor(animalId);

  List<LivestockDailySuggestion> allFor(String animalId) =>
      _svc.suggestionsFor(animalId);

  Set<String> allAnimalIdsWithSuggestions() => _svc.animalIdsWithData;

  Future<void> save(LivestockDailySuggestion suggestion) async {
    await _svc.upsertDailySuggestion(suggestion);
  }

  /// True when the suggestion's stored summary snapshot no longer
  /// matches the animal's last summary. Mirrors the
  /// [DailySuggestionRepository.isStale] pattern so the UI can show
  /// a "stale" badge when the farmer records new deaths / production
  /// after the AI advice was generated.
  bool isStale(
    LivestockDailySuggestion suggestion,
    Map<String, dynamic>? currentSummary,
  ) {
    final snap = suggestion.summarySnapshot;
    if (currentSummary == null) return false;
    if (snap.length != currentSummary.length) return true;
    for (final key in currentSummary.keys) {
      if (snap[key] != currentSummary[key]) return true;
    }
    return false;
  }
}
