/// AI and offline daily advisory recommendations for a specific fish pond.
class FishDailySuggestion {
  FishDailySuggestion({
    required this.id,
    required this.fishPondId,
    required this.date,
    required this.feedingGuidanceBn,
    required this.feedingGuidanceEn,
    required this.oxygenAerationAdviceBn,
    required this.oxygenAerationAdviceEn,
    required this.waterQualityTipsBn,
    required this.waterQualityTipsEn,
    required this.doItems,
    required this.dontItems,
    this.source = 'gemini-3.5-flash-lite',
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();

  final String id;
  final String fishPondId;
  final DateTime date;
  final String feedingGuidanceBn;
  final String feedingGuidanceEn;
  final String oxygenAerationAdviceBn;
  final String oxygenAerationAdviceEn;
  final String waterQualityTipsBn;
  final String waterQualityTipsEn;
  final List<String> doItems;
  final List<String> dontItems;
  final String source;
  final DateTime generatedAt;

  Map<String, dynamic> toMap() => {
    'id': id,
    'fishPondId': fishPondId,
    'date': date.toIso8601String(),
    'feedingGuidanceBn': feedingGuidanceBn,
    'feedingGuidanceEn': feedingGuidanceEn,
    'oxygenAerationAdviceBn': oxygenAerationAdviceBn,
    'oxygenAerationAdviceEn': oxygenAerationAdviceEn,
    'waterQualityTipsBn': waterQualityTipsBn,
    'waterQualityTipsEn': waterQualityTipsEn,
    'doItems': doItems,
    'dontItems': dontItems,
    'source': source,
    'generatedAt': generatedAt.toIso8601String(),
  };

  factory FishDailySuggestion.fromMap(Map<String, dynamic> m) =>
      FishDailySuggestion(
        id: (m['id'] ?? '') as String,
        fishPondId: (m['fishPondId'] ?? '') as String,
        date: m['date'] != null
            ? DateTime.parse(m['date'] as String)
            : DateTime.now(),
        feedingGuidanceBn: (m['feedingGuidanceBn'] ?? '') as String,
        feedingGuidanceEn: (m['feedingGuidanceEn'] ?? '') as String,
        oxygenAerationAdviceBn: (m['oxygenAerationAdviceBn'] ?? '') as String,
        oxygenAerationAdviceEn: (m['oxygenAerationAdviceEn'] ?? '') as String,
        waterQualityTipsBn: (m['waterQualityTipsBn'] ?? '') as String,
        waterQualityTipsEn: (m['waterQualityTipsEn'] ?? '') as String,
        doItems: List<String>.from(m['doItems'] ?? const []),
        dontItems: List<String>.from(m['dontItems'] ?? const []),
        source: (m['source'] ?? 'offline') as String,
        generatedAt: m['generatedAt'] != null
            ? DateTime.parse(m['generatedAt'] as String)
            : DateTime.now(),
      );
}
