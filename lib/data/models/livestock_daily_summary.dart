/// A user's end-of-day production + mortality snapshot for a single
/// [Animal] group. One document per animal per day; reused as input
/// for the AI suggestion so Gemini can spot rising mortality or
/// declining egg yield trends.
///
/// Keyed by `animalId|dateKey` so re-saving for the same day overwrites
/// instead of duplicating.
class LivestockDailySummary {
  LivestockDailySummary({
    required this.id,
    required this.animalId,
    required this.userId,
    required this.dateKey, // 'YYYY-MM-DD'
    required this.dayFromStart,
    required this.liveCount,
    required this.deathsToday,
    required this.totalDeaths,
    this.eggsToday = 0,
    this.milkLitersToday = 0,
    this.feedKg = 0,
    this.notes = '',
    required this.recordedAt,
  });

  final String id;
  final String animalId;
  // userId is non-final so the post-sign-in drain can rewrite the
  // placeholder 'local' uid to the real auth.uid (same trick as Crop).
  String userId;
  final String dateKey;
  final int dayFromStart;
  final int liveCount;
  final int deathsToday;
  final int totalDeaths;
  final int eggsToday;
  final double milkLitersToday;
  final double feedKg;
  final String notes;
  final DateTime recordedAt;

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
    'liveCount': liveCount,
    'deathsToday': deathsToday,
    'totalDeaths': totalDeaths,
    'eggsToday': eggsToday,
    'milkLitersToday': milkLitersToday,
    'feedKg': feedKg,
    'notes': notes,
    'recordedAt': recordedAt.toIso8601String(),
  };

  factory LivestockDailySummary.fromMap(Map<String, dynamic> m) =>
      LivestockDailySummary(
        id: m['id'] as String,
        animalId: m['animalId'] as String,
        userId: (m['userId'] ?? '') as String,
        dateKey: m['dateKey'] as String,
        dayFromStart: (m['dayFromStart'] as num).toInt(),
        liveCount: (m['liveCount'] as num).toInt(),
        deathsToday: ((m['deathsToday'] as num?) ?? 0).toInt(),
        totalDeaths: ((m['totalDeaths'] as num?) ?? 0).toInt(),
        eggsToday: ((m['eggsToday'] as num?) ?? 0).toInt(),
        milkLitersToday: ((m['milkLitersToday'] as num?) ?? 0).toDouble(),
        feedKg: ((m['feedKg'] as num?) ?? 0).toDouble(),
        notes: (m['notes'] ?? '') as String,
        recordedAt: m['recordedAt'] is String
            ? DateTime.parse(m['recordedAt'] as String)
            : DateTime.now(),
      );
}
