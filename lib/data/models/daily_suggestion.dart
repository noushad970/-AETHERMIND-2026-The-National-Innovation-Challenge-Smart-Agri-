/// One AI-generated daily suggestion for a specific crop on a specific day.
///
/// Each [DailySuggestion] is keyed by `cropId|dateKey` (e.g.
/// `a1b2…|2026-08-14`). Because the date is part of the key, re-running
/// the model for the same day overwrites the same record instead of
/// creating a duplicate — Firestore storage stays small and the user
/// only ever sees the latest suggestion for today.
///
/// `checklistSnapshot` stores the crop's activity checklist state at
/// the moment the suggestion was generated, so we can later detect
/// whether the checklist has changed and the suggestion is stale.
class DailySuggestion {
  DailySuggestion({
    required this.id,
    required this.cropId,
    required this.userId,
    required this.dateKey, // 'YYYY-MM-DD' (local date)
    required this.dayFromPlanting,
    required this.cropType,
    required this.variety,
    required this.guidance,
    required this.doItems,
    required this.dontItems,
    required this.generatedAt,
    required this.checklistSnapshot,
    this.source = 'gemini',
  });

  /// Composite id `<cropId>|<dateKey>` — guarantees one row per crop per day.
  final String id;
  final String cropId;
  final String userId;

  /// Local date in 'YYYY-MM-DD' form. Used for keying + display.
  final String dateKey;

  /// Day count from planting when this suggestion was generated.
  final int dayFromPlanting;

  final String cropType;
  final String variety;

  /// Free-form short paragraph Gemini returns (1–3 sentences).
  final String guidance;

  /// Action items the farmer should DO today (max 4 short bullets).
  final List<String> doItems;

  /// Action items the farmer should AVOID today (max 4 short bullets).
  final List<String> dontItems;

  final DateTime generatedAt;

  /// Serialized checklist at the time of generation: list of
  /// `{id, title, isCompleted}`. Stored as plain maps for Firestore
  /// compatibility — no nested adapters needed.
  final List<Map<String, dynamic>> checklistSnapshot;

  /// 'gemini' | 'fallback' | 'cache'
  final String source;

  DailySuggestion copyWith({
    String? guidance,
    List<String>? doItems,
    List<String>? dontItems,
    DateTime? generatedAt,
    List<Map<String, dynamic>>? checklistSnapshot,
    String? source,
  }) {
    return DailySuggestion(
      id: id,
      cropId: cropId,
      userId: userId,
      dateKey: dateKey,
      dayFromPlanting: dayFromPlanting,
      cropType: cropType,
      variety: variety,
      guidance: guidance ?? this.guidance,
      doItems: doItems ?? this.doItems,
      dontItems: dontItems ?? this.dontItems,
      generatedAt: generatedAt ?? this.generatedAt,
      checklistSnapshot: checklistSnapshot ?? this.checklistSnapshot,
      source: source ?? this.source,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'cropId': cropId,
    'userId': userId,
    'dateKey': dateKey,
    'dayFromPlanting': dayFromPlanting,
    'cropType': cropType,
    'variety': variety,
    'guidance': guidance,
    'doItems': doItems,
    'dontItems': dontItems,
    'generatedAt': generatedAt.toIso8601String(),
    'checklistSnapshot': checklistSnapshot,
    'source': source,
  };

  factory DailySuggestion.fromMap(Map<String, dynamic> m) => DailySuggestion(
    id: m['id'] as String,
    cropId: m['cropId'] as String,
    userId: (m['userId'] ?? '') as String,
    dateKey: m['dateKey'] as String,
    dayFromPlanting: (m['dayFromPlanting'] as num).toInt(),
    cropType: (m['cropType'] ?? '') as String,
    variety: (m['variety'] ?? '') as String,
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
    checklistSnapshot: ((m['checklistSnapshot'] as List?) ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList(growable: false),
    source: (m['source'] ?? 'gemini') as String,
  );

  /// Build the canonical `<cropId>|<dateKey>` id for today.
  static String buildId(String cropId, String dateKey) => '$cropId|$dateKey';

  /// 'YYYY-MM-DD' from a local DateTime.
  static String dateKeyFor(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$y-$m-$dd';
  }
}
