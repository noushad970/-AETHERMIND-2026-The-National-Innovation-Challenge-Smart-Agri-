import 'package:cloud_firestore/cloud_firestore.dart';

/// Per-user, per-day AI weather tip. Stored in
/// `weatherDailyAdvice/{userId}_{dateKey}` so a same-day reopen reads
/// the cached Firestore doc instead of calling Gemini again. The
/// document is regenerated when the local date flips.
class WeatherDailyAdvice {
  WeatherDailyAdvice({
    required this.id,
    required this.userId,
    required this.dateKey,
    required this.headline,
    required this.summary,
    required this.doItems,
    required this.dontItems,
    required this.weatherSnapshot,
    required this.generatedAt,
    required this.source,
  });

  /// `{userId}_{YYYY-MM-DD}` — same convention used elsewhere.
  final String id;
  final String userId;
  final String dateKey;
  final String headline;
  final String summary;
  final List<String> doItems;
  final List<String> dontItems;

  /// Trimmed weather payload captured when the tip was generated.
  /// Used for staleness display ("based on N°/rain/Mh" etc).
  final Map<String, dynamic> weatherSnapshot;
  final DateTime generatedAt;

  /// `gemini`, `fallback`, or `cache`.
  final String source;

  static String dateKeyFor(DateTime t) {
    final y = t.year.toString().padLeft(4, '0');
    final m = t.month.toString().padLeft(2, '0');
    final d = t.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String buildId(String userId, String dateKey) => '${userId}_$dateKey';

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'userId': userId,
    'dateKey': dateKey,
    'headline': headline,
    'summary': summary,
    'doItems': doItems,
    'dontItems': dontItems,
    'weatherSnapshot': weatherSnapshot,
    'generatedAt': Timestamp.fromDate(generatedAt),
    'source': source,
  };

  factory WeatherDailyAdvice.fromMap(Map<String, dynamic> m) {
    final ts = m['generatedAt'];
    DateTime generated;
    if (ts is Timestamp) {
      generated = ts.toDate();
    } else if (ts is DateTime) {
      generated = ts;
    } else {
      generated = DateTime.now();
    }
    return WeatherDailyAdvice(
      id: (m['id'] ?? '') as String,
      userId: (m['userId'] ?? '') as String,
      dateKey: (m['dateKey'] ?? '') as String,
      headline: (m['headline'] ?? '') as String,
      summary: (m['summary'] ?? '') as String,
      doItems: ((m['doItems'] as List?) ?? const <dynamic>[])
          .map((e) => e.toString())
          .toList(growable: false),
      dontItems: ((m['dontItems'] as List?) ?? const <dynamic>[])
          .map((e) => e.toString())
          .toList(growable: false),
      weatherSnapshot:
          ((m['weatherSnapshot'] as Map?) ?? const <String, dynamic>{})
              .cast<String, dynamic>(),
      generatedAt: generated,
      source: (m['source'] ?? 'gemini') as String,
    );
  }
}
