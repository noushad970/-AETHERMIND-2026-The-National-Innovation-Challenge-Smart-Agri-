/// Daily logged metrics for a fish pond (feed amount in kg, water temp, dissolved oxygen, mortality).
class FishDailySummary {
  FishDailySummary({
    required this.id,
    required this.fishPondId,
    required this.date,
    this.feedGivenKg = 0.0,
    this.waterTempC = 28.0,
    this.dissolvedOxygenPpm = 5.5,
    this.deadCount = 0,
    this.notes = '',
    this.swimmingAerationDone = false,
  });

  final String id;
  final String fishPondId;
  final DateTime date;
  double feedGivenKg;
  double waterTempC;
  double dissolvedOxygenPpm;
  int deadCount;
  String notes;
  bool swimmingAerationDone;

  Map<String, dynamic> toMap() => {
    'id': id,
    'fishPondId': fishPondId,
    'date': date.toIso8601String(),
    'feedGivenKg': feedGivenKg,
    'waterTempC': waterTempC,
    'dissolvedOxygenPpm': dissolvedOxygenPpm,
    'deadCount': deadCount,
    'notes': notes,
    'swimmingAerationDone': swimmingAerationDone,
  };

  factory FishDailySummary.fromMap(Map<String, dynamic> m) => FishDailySummary(
    id: (m['id'] ?? '') as String,
    fishPondId: (m['fishPondId'] ?? '') as String,
    date: m['date'] != null
        ? DateTime.parse(m['date'] as String)
        : DateTime.now(),
    feedGivenKg: ((m['feedGivenKg'] as num?) ?? 0.0).toDouble(),
    waterTempC: ((m['waterTempC'] as num?) ?? 28.0).toDouble(),
    dissolvedOxygenPpm: ((m['dissolvedOxygenPpm'] as num?) ?? 5.5).toDouble(),
    deadCount: ((m['deadCount'] as num?) ?? 0).toInt(),
    notes: (m['notes'] ?? '') as String,
    swimmingAerationDone: (m['swimmingAerationDone'] as bool?) ?? false,
  );
}
