
import '../../core/constants/app_constants.dart';

/// Gemini-powered daily guidance for an [Animal]. Same keying pattern
/// as [DailySuggestion] (`animalId|dateKey`) so we keep one row per
/// day per animal and stale-state detection works the same way.
class LivestockDailySuggestion {
  LivestockDailySuggestion({
    required this.id,
    required this.animalId,
    required this.userId,
    required this.dateKey,
    required this.dayFromStart,
    required this.species,
    required this.purpose,
    required this.guidance,
    required this.doItems,
    required this.dontItems,
    required this.generatedAt,
    required this.summarySnapshot,
    this.source = 'gemini',
  });

  final String id;
  final String animalId;
  // userId is non-final so the post-sign-in drain can rewrite the
  // placeholder 'local' uid to the real auth.uid (same trick as Crop).
  String userId;
  final String dateKey;
  final int dayFromStart;
  final String species;
  final String purpose;
  final String guidance;
  final List<String> doItems;
  final List<String> dontItems;
  final DateTime generatedAt;

  /// Last-known summary at generation time — lets the UI detect
  /// whether the daily numbers have moved and the advice is stale.
  final Map<String, dynamic> summarySnapshot;
  final String source;

  static String buildId(String animalId, String dateKey) =>
      '$animalId|$dateKey';

  static String dateKeyFor(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$y-$m-$dd';
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'animalId': animalId,
    'userId': userId,
    'dateKey': dateKey,
    'dayFromStart': dayFromStart,
    'species': species,
    'purpose': purpose,
    'guidance': guidance,
    'doItems': doItems,
    'dontItems': dontItems,
    'generatedAt': generatedAt.toIso8601String(),
    'summarySnapshot': summarySnapshot,
    'source': source,
  };

  factory LivestockDailySuggestion.fromMap(Map<String, dynamic> m) =>
      LivestockDailySuggestion(
        id: m['id'] as String,
        animalId: m['animalId'] as String,
        userId: (m['userId'] ?? '') as String,
        dateKey: m['dateKey'] as String,
        dayFromStart: (m['dayFromStart'] as num).toInt(),
        species: (m['species'] ?? '') as String,
        purpose: (m['purpose'] ?? AppConstants.purposeMixed) as String,
        guidance: (m['guidance'] ?? '') as String,
        doItems: ((m['doItems'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(growable: false),
        dontItems: ((m['dontItems'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(growable: false),
        generatedAt: m['generatedAt'] is String
            ? DateTime.parse(m['generatedAt'] as String)
            : DateTime.now(),
        summarySnapshot: ((m['summarySnapshot'] as Map?) ?? const {}).map(
          (k, v) => MapEntry(k.toString(), v),
        ),
        source: (m['source'] ?? 'gemini') as String,
      );
}

