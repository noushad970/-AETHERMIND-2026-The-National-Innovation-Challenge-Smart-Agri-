import 'crop_activity.dart';

/// A crop planted by the user. Linked to its [activities] (computed at
/// creation) and its tree list (for orchards).
class Crop {
  Crop({
    required this.id,
    required this.userId,
    required this.cropType, // Rice, Wheat, Tomato, ...
    required this.variety,
    required this.plantingDate,
    required this.landAreaDecimal,
    required this.totalGrowthDays,
    required this.estimatedHarvestDate,
    this.numberOfTrees,
    this.deadTrees = 0,
    this.notes = '',
    this.imageUrl,
    this.healthStatus = 'good', // good | warning | critical
    this.activities = const <CropActivity>[],
    this.newlyPlantedTrees = 0,
  });

  final String id;
  // userId is mutable so the realtime services can re-tag a crop's
  // owner when the auth user changes (sign-in / sign-out).
  String userId;
  final String cropType;
  final String variety;
  final DateTime plantingDate;
  final double landAreaDecimal;
  final int totalGrowthDays;
  final DateTime estimatedHarvestDate;
  final int? numberOfTrees; // null for non-orchard crops
  int deadTrees;
  String notes;
  String? imageUrl;
  String healthStatus;
  List<CropActivity> activities;
  int newlyPlantedTrees;

  /// Trees still considered alive at this point in time.
  int get liveTrees => (numberOfTrees ?? 0) + newlyPlantedTrees - deadTrees;

  int get daysSincePlanting {
    final now = DateTime.now();
    return now.difference(plantingDate).inDays.clamp(0, 1 << 30);
  }

  int get daysRemainingUntilHarvest {
    final now = DateTime.now();
    return estimatedHarvestDate.difference(now).inDays.clamp(0, 1 << 30);
  }

  String get currentGrowthStage => getCurrentGrowthStage(false);

  String getCurrentGrowthStage(bool isBn) {
    final days = daysSincePlanting;
    if (days <= 0) return isBn ? 'সবেমাত্র রোপণকৃত' : 'Just planted';
    if (days >= totalGrowthDays) return isBn ? 'ফসল তোলার উপযোগী' : 'Ready for harvest';
    final pct = days / totalGrowthDays;
    if (pct < 0.15) return isBn ? 'চারা গজানো পর্যায়' : 'Seedling stage';
    if (pct < 0.35) return isBn ? 'অঙ্গজ বৃদ্ধি পর্যায়' : 'Vegetative growth';
    if (pct < 0.55) return isBn ? 'ফুল ফোটার পর্যায়' : 'Flowering stage';
    if (pct < 0.80) return isBn ? 'ফল / দানা গঠন পর্যায়' : 'Fruit / grain filling';
    return isBn ? 'পরিপক্বতা পর্যায়' : 'Maturity stage';
  }

  double get progress {
    final days = daysSincePlanting;
    if (totalGrowthDays == 0) return 0;
    return (days / totalGrowthDays).clamp(0.0, 1.0);
  }

  int get completedActivityCount =>
      activities.where((a) => a.isCompleted).length;

  int get upcomingActivityCount =>
      activities.where((a) => !a.isCompleted).length;

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'cropType': cropType,
    'variety': variety,
    'plantingDate': plantingDate.toIso8601String(),
    'landAreaDecimal': landAreaDecimal,
    'totalGrowthDays': totalGrowthDays,
    'estimatedHarvestDate': estimatedHarvestDate.toIso8601String(),
    'numberOfTrees': numberOfTrees,
    'deadTrees': deadTrees,
    'notes': notes,
    'imageUrl': imageUrl,
    'healthStatus': healthStatus,
    'activities': activities.map((a) => a.toMap()).toList(),
    'newlyPlantedTrees': newlyPlantedTrees,
  };

  factory Crop.fromMap(Map<String, dynamic> m) => Crop(
    id: m['id'] as String,
    userId: m['userId'] as String,
    cropType: m['cropType'] as String,
    variety: (m['variety'] ?? '') as String,
    plantingDate: DateTime.parse(m['plantingDate'] as String),
    landAreaDecimal: (m['landAreaDecimal'] as num).toDouble(),
    totalGrowthDays: m['totalGrowthDays'] as int,
    estimatedHarvestDate: DateTime.parse(m['estimatedHarvestDate'] as String),
    numberOfTrees: m['numberOfTrees'] as int?,
    deadTrees: (m['deadTrees'] ?? 0) as int,
    notes: (m['notes'] ?? '') as String,
    imageUrl: m['imageUrl'] as String?,
    healthStatus: (m['healthStatus'] ?? 'good') as String,
    activities: ((m['activities'] as List?) ?? const [])
        .map((e) => CropActivity.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList(),
    newlyPlantedTrees: (m['newlyPlantedTrees'] ?? 0) as int,
  );
}
