import 'bd_fishes_catalog.dart';
import 'fish_activity.dart';

/// A fish pond / culture batch entity tracked in the farm.
class FishPond {
  FishPond({
    required this.id,
    required this.userId,
    required this.speciesId,
    required this.speciesName,
    required this.pondName,
    required this.pondAreaDecimals,
    required this.fingerlingCount,
    this.deadCount = 0,
    required this.stockingDate,
    required this.targetHarvestDays,
    this.feedType = 'floating', // floating, sinking, homemade, mixed
    this.notes = '',
    this.activities = const <FishActivity>[],
    this.waterDepthFeet = 4.5,
    this.targetWeightGrams = 800,
  });

  final String id;
  String userId;
  final String speciesId;
  final String speciesName;
  final String pondName;
  final double pondAreaDecimals;
  int fingerlingCount;
  int deadCount;
  final DateTime stockingDate;
  final int targetHarvestDays;
  final String feedType;
  String notes;
  List<FishActivity> activities;
  final double waterDepthFeet;
  final double targetWeightGrams;

  /// Live fish population in the pond.
  int get liveCount => (fingerlingCount - deadCount).clamp(0, 1 << 30);

  int get daysSinceStocking {
    final now = DateTime.now();
    return now.difference(stockingDate).inDays.clamp(0, 1 << 30);
  }

  double get progress {
    if (targetHarvestDays <= 0) return 0.0;
    return (daysSinceStocking / targetHarvestDays).clamp(0.0, 1.0);
  }

  DateTime get estimatedHarvestDate =>
      stockingDate.add(Duration(days: targetHarvestDays));

  int get daysUntilHarvest {
    final now = DateTime.now();
    return estimatedHarvestDate.difference(now).inDays.clamp(0, 1000);
  }

  BdFishSpecies get speciesData =>
      BdFishesCatalog.findById(speciesId.isNotEmpty ? speciesId : speciesName);

  int get completedActivityCount =>
      activities.where((a) => a.isCompleted).length;

  int get upcomingActivityCount =>
      activities.where((a) => !a.isCompleted).length;

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'speciesId': speciesId,
    'speciesName': speciesName,
    'pondName': pondName,
    'pondAreaDecimals': pondAreaDecimals,
    'fingerlingCount': fingerlingCount,
    'deadCount': deadCount,
    'stockingDate': stockingDate.toIso8601String(),
    'targetHarvestDays': targetHarvestDays,
    'feedType': feedType,
    'notes': notes,
    'activities': activities.map((a) => a.toMap()).toList(),
    'waterDepthFeet': waterDepthFeet,
    'targetWeightGrams': targetWeightGrams,
  };

  factory FishPond.fromMap(Map<String, dynamic> m) => FishPond(
    id: (m['id'] ?? '') as String,
    userId: (m['userId'] ?? '') as String,
    speciesId: (m['speciesId'] ?? 'rui') as String,
    speciesName: (m['speciesName'] ?? 'রুই মাছ') as String,
    pondName: (m['pondName'] ?? 'পুকুর') as String,
    pondAreaDecimals: ((m['pondAreaDecimals'] as num?) ?? 20.0).toDouble(),
    fingerlingCount: ((m['fingerlingCount'] as num?) ?? 1000).toInt(),
    deadCount: ((m['deadCount'] as num?) ?? 0).toInt(),
    stockingDate: m['stockingDate'] != null
        ? DateTime.parse(m['stockingDate'] as String)
        : DateTime.now(),
    targetHarvestDays: ((m['targetHarvestDays'] as num?) ?? 180).toInt(),
    feedType: (m['feedType'] ?? 'floating') as String,
    notes: (m['notes'] ?? '') as String,
    activities: ((m['activities'] as List?) ?? const [])
        .map((e) => FishActivity.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList(),
    waterDepthFeet: ((m['waterDepthFeet'] as num?) ?? 4.5).toDouble(),
    targetWeightGrams: ((m['targetWeightGrams'] as num?) ?? 800.0).toDouble(),
  );

  FishPond copyWith({
    String? id,
    String? userId,
    String? speciesId,
    String? speciesName,
    String? pondName,
    double? pondAreaDecimals,
    int? fingerlingCount,
    int? deadCount,
    DateTime? stockingDate,
    int? targetHarvestDays,
    String? feedType,
    String? notes,
    List<FishActivity>? activities,
    double? waterDepthFeet,
    double? targetWeightGrams,
  }) {
    return FishPond(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      speciesId: speciesId ?? this.speciesId,
      speciesName: speciesName ?? this.speciesName,
      pondName: pondName ?? this.pondName,
      pondAreaDecimals: pondAreaDecimals ?? this.pondAreaDecimals,
      fingerlingCount: fingerlingCount ?? this.fingerlingCount,
      deadCount: deadCount ?? this.deadCount,
      stockingDate: stockingDate ?? this.stockingDate,
      targetHarvestDays: targetHarvestDays ?? this.targetHarvestDays,
      feedType: feedType ?? this.feedType,
      notes: notes ?? this.notes,
      activities: activities ?? this.activities,
      waterDepthFeet: waterDepthFeet ?? this.waterDepthFeet,
      targetWeightGrams: targetWeightGrams ?? this.targetWeightGrams,
    );
  }
}
