class SoilType {
  const SoilType({
    required this.id,
    required this.name,
    required this.nameBn,
    required this.moistureRetentionFactor,
    required this.drainageRate,
    required this.recommendedIntervalDays,
    required this.description,
  });

  final String id;
  final String name;
  final String nameBn;
  final double moistureRetentionFactor; // 0.2 (low) to 0.8 (high)
  final String drainageRate;
  final int recommendedIntervalDays;
  final String description;

  static const List<SoilType> presets = [
    SoilType(
      id: 'etel',
      name: 'Etel / Clay',
      nameBn: 'এঁটেল মাটি',
      moistureRetentionFactor: 0.8,
      drainageRate: 'Slow (ধীর গতিতে নিষ্কাশন)',
      recommendedIntervalDays: 5,
      description: 'High water-holding capacity. Requires longer gaps between irrigations to avoid waterlogging.',
    ),
    SoilType(
      id: 'doash',
      name: 'Doash / Loam',
      nameBn: 'দোঁআশ মাটি',
      moistureRetentionFactor: 0.6,
      drainageRate: 'Optimal (আদর্শ নিষ্কাশন)',
      recommendedIntervalDays: 4,
      description: 'Ideal agricultural soil balance. Good moisture retention and healthy root aeration.',
    ),
    SoilType(
      id: 'bele_doash',
      name: 'Bele-Doash / Sandy Loam',
      nameBn: 'বেলে-দোঁআশ মাটি',
      moistureRetentionFactor: 0.45,
      drainageRate: 'Moderate-Fast (দ্রুত নিষ্কাশন)',
      recommendedIntervalDays: 3,
      description: 'Drains faster than loam. Requires moderate frequency irrigation.',
    ),
    SoilType(
      id: 'bele',
      name: 'Bele / Sandy',
      nameBn: 'বেলে মাটি',
      moistureRetentionFactor: 0.3,
      drainageRate: 'Very Fast (খুব দ্রুত নিষ্কাশন)',
      recommendedIntervalDays: 2,
      description: 'Low water retention. Requires frequent light irrigation to maintain root zone moisture.',
    ),
  ];
}
