import '../../core/constants/app_constants.dart';

/// A group of farm animals tracked together under one [species] /
/// [purpose] / [startDate].
///
/// Instead of tracking individual birds (impractical at scale), we
/// track the population as a whole: total count, deaths, and per-day
/// production tallies (eggs, milk). The model mirrors [Crop] so the
/// patterns (live count, days since start, daily checklist, AI advice)
/// stay consistent across the app.
class Animal {
  Animal({
    required this.id,
    required this.userId,
    required this.species,
    required this.purpose,
    required this.startDate,
    required this.totalCount,
    this.deadCount = 0,
    this.notes = '',
    this.activities = const <LivestockActivity>[],
  });

  final String id;
  // userId is mutable so the realtime services can re-tag an animal's
  // owner when the auth user changes (sign-in / sign-out).
  String userId;
  final String species;
  final String purpose; // meat | egg | dairy | mixed
  final DateTime startDate;
  int totalCount;
  int deadCount;
  String notes;
  List<LivestockActivity> activities;

  /// Animals currently alive (total minus deaths).
  int get liveCount => (totalCount - deadCount).clamp(0, 1 << 30);

  int get daysSinceStart {
    final now = DateTime.now();
    return now.difference(startDate).inDays.clamp(0, 1 << 30);
  }

  int get completedActivityCount =>
      activities.where((a) => a.isCompleted).length;

  int get upcomingActivityCount =>
      activities.where((a) => !a.isCompleted).length;

  /// Production output expected for this animal group. Display-only;
  /// the actual numbers live in [LivestockDailySummary].
  ///
  /// Both checks require **species AND purpose** to agree —
  /// selecting a "cow" with `purpose = egg` would otherwise show
  /// an egg-production card. See [AppConstants.isEggProducingSpecies]
  /// and [AppConstants.isMilkProducingSpecies].
  bool get producesEggs =>
      purpose == AppConstants.purposeEgg &&
      AppConstants.isEggProducingSpecies(species);
  bool get producesMilk =>
      (purpose == AppConstants.purposeDairy ||
          purpose == AppConstants.purposeMixed) &&
      AppConstants.isMilkProducingSpecies(species);

  /// Convenience aliases for templates that ask "does this animal
  /// naturally lay eggs / give milk" — purely species-based.
  bool get isEggProducing => AppConstants.isEggProducingSpecies(species);
  bool get isMilkProducing => AppConstants.isMilkProducingSpecies(species);

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'species': species,
    'purpose': purpose,
    'startDate': startDate.toIso8601String(),
    'totalCount': totalCount,
    'deadCount': deadCount,
    'notes': notes,
    'activities': activities.map((a) => a.toMap()).toList(),
  };

  factory Animal.fromMap(Map<String, dynamic> m) => Animal(
    id: m['id'] as String,
    userId: (m['userId'] ?? '') as String,
    species: m['species'] as String,
    purpose: (m['purpose'] ?? AppConstants.purposeMixed) as String,
    startDate: DateTime.parse(m['startDate'] as String),
    totalCount: (m['totalCount'] as num).toInt(),
    deadCount: ((m['deadCount'] as num?) ?? 0).toInt(),
    notes: (m['notes'] ?? '') as String,
    activities: ((m['activities'] as List?) ?? const [])
        .map(
          (e) => LivestockActivity.fromMap(Map<String, dynamic>.from(e as Map)),
        )
        .toList(),
  );
}

/// Stored in the `users/{uid}/livestock/{livestockId}` Firestore
/// collection. No local cache.

/// A single scheduled task on an [Animal] (vaccination, feeding,
/// cleaning, etc.). Lifecycle mirrors [CropActivity] so the
/// countdown-aware checklist UI can be reused.
///
/// Recurring tasks (e.g. daily feeding, weekly cleaning) are
/// represented by setting [repeatIntervalDays] > 0. When the user
/// marks such a task complete, the repository auto-creates the
/// next occurrence at `scheduledDate + repeatIntervalDays` — the
/// current record stays as the historical "done" entry. 0 means
/// a one-off event (vaccination, deworming).
class LivestockActivity {
  LivestockActivity({
    required this.id,
    required this.animalId,
    required this.title,
    this.titleBn = '',
    this.description = '',
    this.descriptionBn = '',
    required this.dayFromStart,
    required this.scheduledDate,
    this.category = AppConstants.lcatGeneral,
    this.isCompleted = false,
    this.completedAt,
    this.repeatIntervalDays = 0,
  });

  final String id;
  final String animalId;
  final String title;
  final String titleBn;
  final String description;
  final String descriptionBn;
  final int dayFromStart;
  final DateTime scheduledDate;
  final String category;
  bool isCompleted;
  DateTime? completedAt;
  int repeatIntervalDays;

  String getTitle(bool isBn) {
    if (isBn && titleBn.isNotEmpty) return titleBn;
    return title;
  }

  String getDescription(bool isBn) {
    if (isBn && descriptionBn.isNotEmpty) return descriptionBn;
    return description;
  }

  LivestockActivity copyWith({
    bool? isCompleted,
    DateTime? completedAt,
    int? repeatIntervalDays,
    DateTime? scheduledDate,
    String? title,
    String? titleBn,
    String? description,
    String? descriptionBn,
    String? category,
  }) {
    return LivestockActivity(
      id: id,
      animalId: animalId,
      title: title ?? this.title,
      titleBn: titleBn ?? this.titleBn,
      description: description ?? this.description,
      descriptionBn: descriptionBn ?? this.descriptionBn,
      dayFromStart: dayFromStart,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      repeatIntervalDays: repeatIntervalDays ?? this.repeatIntervalDays,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'animalId': animalId,
    'title': title,
    'titleBn': titleBn.isNotEmpty ? titleBn : title,
    'description': description,
    'descriptionBn': descriptionBn.isNotEmpty ? descriptionBn : description,
    'dayFromStart': dayFromStart,
    'scheduledDate': scheduledDate.toIso8601String(),
    'category': category,
    'isCompleted': isCompleted,
    'completedAt': completedAt?.toIso8601String(),
    'repeatIntervalDays': repeatIntervalDays,
  };

  factory LivestockActivity.fromMap(Map<String, dynamic> m) =>
      LivestockActivity(
        id: m['id'] as String,
        animalId: m['animalId'] as String,
        title: (m['title'] ?? '') as String,
        titleBn: (m['titleBn'] ?? m['title'] ?? '') as String,
        description: (m['description'] ?? '') as String,
        descriptionBn: (m['descriptionBn'] ?? m['description'] ?? '') as String,
        dayFromStart: (m['dayFromStart'] as num).toInt(),
        scheduledDate: DateTime.parse(m['scheduledDate'] as String),
        category: (m['category'] ?? AppConstants.lcatGeneral) as String,
        isCompleted: (m['isCompleted'] ?? false) as bool,
        completedAt: m['completedAt'] == null
            ? null
            : DateTime.parse(m['completedAt'] as String),
        // Field added after the initial release — default to 0 for
        // any record written before repeatIntervalDays existed.
        repeatIntervalDays: (m['repeatIntervalDays'] as num?)?.toInt() ?? 0,
      );
}
