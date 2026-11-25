class SeasonStageGuideline {
  const SeasonStageGuideline({
    required this.stageNameBn,
    required this.stageNameEn,
    required this.dayStart,
    required this.dayEnd,
    required this.keyActivitiesBn,
    required this.keyActivitiesEn,
    required this.waterAdviceBn,
    required this.fertilizerAdviceBn,
    required this.pestPreventionBn,
  });

  final String stageNameBn;
  final String stageNameEn;
  final int dayStart;
  final int dayEnd;
  final String keyActivitiesBn;
  final String keyActivitiesEn;
  final String waterAdviceBn;
  final String fertilizerAdviceBn;
  final String pestPreventionBn;
}

class CropCatalogEntry {
  const CropCatalogEntry({
    required this.id,
    required this.nameBn,
    required this.nameEn,
    required this.scientificName,
    required this.category,
    required this.durationDays,
    required this.idealSeason,
    required this.recommendedSoil,
    required this.descriptionBn,
    required this.descriptionEn,
    required this.guidelines,
  });

  final String id;
  final String nameBn;
  final String nameEn;
  final String scientificName;
  final String category; // 'Grains', 'Vegetables', 'Spices', 'Pulses', 'Fruits', 'Trees', 'Cash Crops'
  final int durationDays;
  final String idealSeason;
  final String recommendedSoil;
  final String descriptionBn;
  final String descriptionEn;
  final List<SeasonStageGuideline> guidelines;
}
