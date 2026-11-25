class FishActivity {
  FishActivity({
    required this.id,
    required this.fishPondId,
    required this.title,
    required this.titleBn,
    required this.description,
    required this.descriptionBn,
    required this.dayFromStocking,
    required this.scheduledDate,
    this.isCompleted = false,
    this.completedAt,
    this.category = 'general', // feeding, oxygen_aeration, water_quality, sampling, treatment
    this.suggestedTime = '08:00 AM',
  });

  final String id;
  final String fishPondId;
  final String title;
  final String titleBn;
  final String description;
  final String descriptionBn;
  final int dayFromStocking;
  final DateTime scheduledDate;
  bool isCompleted;
  DateTime? completedAt;
  final String category;
  final String suggestedTime;

  bool get isToday {
    final now = DateTime.now();
    return scheduledDate.year == now.year &&
        scheduledDate.month == now.month &&
        scheduledDate.day == now.day;
  }

  String getTitle(bool isBn) {
    if (isBn && titleBn.trim().isNotEmpty) return titleBn;
    return title.isNotEmpty ? title : titleBn;
  }

  String getDescription(bool isBn) {
    if (isBn && descriptionBn.trim().isNotEmpty) return descriptionBn;
    return description.isNotEmpty ? description : descriptionBn;
  }

  bool get isDueOrPast {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sched = DateTime(
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
    );
    return !sched.isAfter(today);
  }

  bool get isOxygenAeration => category == 'oxygen_aeration';
  bool get isFeeding => category == 'feeding';

  FishActivity copyWith({
    String? id,
    String? fishPondId,
    String? title,
    String? titleBn,
    String? description,
    String? descriptionBn,
    int? dayFromStocking,
    DateTime? scheduledDate,
    bool? isCompleted,
    DateTime? completedAt,
    String? category,
    String? suggestedTime,
  }) {
    return FishActivity(
      id: id ?? this.id,
      fishPondId: fishPondId ?? this.fishPondId,
      title: title ?? this.title,
      titleBn: titleBn ?? this.titleBn,
      description: description ?? this.description,
      descriptionBn: descriptionBn ?? this.descriptionBn,
      dayFromStocking: dayFromStocking ?? this.dayFromStocking,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      category: category ?? this.category,
      suggestedTime: suggestedTime ?? this.suggestedTime,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'fishPondId': fishPondId,
    'title': title,
    'titleBn': titleBn,
    'description': description,
    'descriptionBn': descriptionBn,
    'dayFromStocking': dayFromStocking,
    'scheduledDate': scheduledDate.toIso8601String(),
    'isCompleted': isCompleted,
    'completedAt': completedAt?.toIso8601String(),
    'category': category,
    'suggestedTime': suggestedTime,
  };

  factory FishActivity.fromMap(Map<String, dynamic> m) => FishActivity(
    id: (m['id'] ?? '') as String,
    fishPondId: (m['fishPondId'] ?? '') as String,
    title: (m['title'] ?? '') as String,
    titleBn: (m['titleBn'] ?? m['title'] ?? '') as String,
    description: (m['description'] ?? '') as String,
    descriptionBn: (m['descriptionBn'] ?? m['description'] ?? '') as String,
    dayFromStocking: ((m['dayFromStocking'] as num?) ?? 0).toInt(),
    scheduledDate: m['scheduledDate'] != null
        ? DateTime.parse(m['scheduledDate'] as String)
        : DateTime.now(),
    isCompleted: (m['isCompleted'] as bool?) ?? false,
    completedAt: m['completedAt'] != null
        ? DateTime.parse(m['completedAt'] as String)
        : null,
    category: (m['category'] ?? 'general') as String,
    suggestedTime: (m['suggestedTime'] ?? '08:00 AM') as String,
  );
}
