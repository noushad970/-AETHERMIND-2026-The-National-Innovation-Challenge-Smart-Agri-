import '../models/daily_suggestion.dart';
import '../services/crop_daily_suggestion_service.dart';

/// Repository for [DailySuggestion] entities.
///
/// Each crop has at most one [DailySuggestion] per local date, keyed
/// by `<cropId>|<YYYY-MM-DD>`. Calling [save] with an existing id
/// overwrites the previous record — there is no per-day history by
/// design. Firestore storage stays bounded (1 doc per crop per day
/// per user) and the user only ever sees the latest suggestion for
/// "today".
///
/// Reads come from the [CropDailySuggestionService] Firestore
/// stream; writes go through the same service.
class DailySuggestionRepository {
  DailySuggestionRepository({CropDailySuggestionService? svc})
    : _svc = svc ?? CropDailySuggestionService();

  final CropDailySuggestionService _svc;

  /// Today's suggestion for [cropId], or `null` if none has been
  /// generated for today yet.
  DailySuggestion? todayFor(String cropId) {
    final dateKey = DailySuggestion.dateKeyFor(DateTime.now());
    return _svc
        .suggestionsFor(cropId)
        .where((s) => s.dateKey == dateKey)
        .cast<DailySuggestion?>()
        .firstWhere((_) => true, orElse: () => null);
  }

  /// Most recent stored suggestion for [cropId], regardless of date.
  /// Useful for showing the last AI thought when today's record is
  /// missing (e.g. very early morning before the first generation).
  DailySuggestion? latestFor(String cropId) => _svc.latestFor(cropId);

  /// All stored suggestions for [cropId], newest first.
  List<DailySuggestion> allFor(String cropId) => _svc.suggestionsFor(cropId);

  /// All distinct crop ids that have at least one stored suggestion.
  Set<String> allCropIdsWithSuggestions() => _svc.cropIdsWithSuggestions;

  Future<void> save(DailySuggestion suggestion) async {
    await _svc.save(suggestion);
  }

  /// True when the suggestion's stored checklist snapshot no longer
  /// matches the crop's actual checklist. Lets the UI show a small
  /// "stale" badge so the user knows to refresh.
  bool isStale(
    DailySuggestion suggestion,
    List<({String id, bool isCompleted})> current,
  ) {
    if (suggestion.checklistSnapshot.length != current.length) return true;
    final byId = {for (final c in current) c.id: c.isCompleted};
    for (final item in suggestion.checklistSnapshot) {
      final id = item['id'] as String?;
      final was = item['isCompleted'] as bool? ?? false;
      if (id == null) return true;
      if (byId[id] != was) return true;
    }
    return false;
  }
}
