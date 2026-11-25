/// A single activity in a crop's cultivation timeline (Day 7 - First irrigation,
/// Day 20 - Apply first fertilizer, etc.).
class CropActivity {
  CropActivity({
    required this.id,
    required this.cropId,
    required this.title,
    this.titleBn = '',
    this.description = '',
    this.descriptionBn = '',
    required this.dayFromPlanting,
    required this.scheduledDate,
    this.category = 'general',
    this.isCompleted = false,
    this.completedAt,
    this.notificationId,
  });

  final String id;
  final String cropId;
  final String title;
  final String titleBn;
  final String description;
  final String descriptionBn;
  final int dayFromPlanting; // 1-based day count from planting
  final DateTime scheduledDate;
  final String
  category; // irrigation | fertilizer | pest | weed | harvest | general
  bool isCompleted;
  DateTime? completedAt;
  int? notificationId;

  String getTitle(bool isBn) {
    if (isBn && titleBn.isNotEmpty) return titleBn;
    return title;
  }

  String getDescription(bool isBn) {
    if (isBn && descriptionBn.isNotEmpty) return descriptionBn;
    return description;
  }

  CropActivity copyWith({
    String? title,
    String? titleBn,
    String? description,
    String? descriptionBn,
    bool? isCompleted,
    DateTime? completedAt,
    int? notificationId,
  }) {
    return CropActivity(
      id: id,
      cropId: cropId,
      title: title ?? this.title,
      titleBn: titleBn ?? this.titleBn,
      description: description ?? this.description,
      descriptionBn: descriptionBn ?? this.descriptionBn,
      dayFromPlanting: dayFromPlanting,
      scheduledDate: scheduledDate,
      category: category,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      notificationId: notificationId ?? this.notificationId,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'cropId': cropId,
    'title': title,
    'titleBn': titleBn.isNotEmpty ? titleBn : title,
    'description': description,
    'descriptionBn': descriptionBn.isNotEmpty ? descriptionBn : description,
    'dayFromPlanting': dayFromPlanting,
    'scheduledDate': scheduledDate.toIso8601String(),
    'category': category,
    'isCompleted': isCompleted,
    'completedAt': completedAt?.toIso8601String(),
    'notificationId': notificationId,
  };

  factory CropActivity.fromMap(Map<String, dynamic> m) => CropActivity(
    id: m['id'] as String,
    cropId: m['cropId'] as String,
    title: (m['title'] ?? '') as String,
    titleBn: (m['titleBn'] ?? m['title'] ?? '') as String,
    description: (m['description'] ?? '') as String,
    descriptionBn: (m['descriptionBn'] ?? m['description'] ?? '') as String,
    dayFromPlanting: m['dayFromPlanting'] as int,
    scheduledDate: DateTime.parse(m['scheduledDate'] as String),
    category: (m['category'] ?? 'general') as String,
    isCompleted: (m['isCompleted'] ?? false) as bool,
    completedAt: m['completedAt'] == null
        ? null
        : DateTime.parse(m['completedAt'] as String),
    notificationId: m['notificationId'] as int?,
  );
}
