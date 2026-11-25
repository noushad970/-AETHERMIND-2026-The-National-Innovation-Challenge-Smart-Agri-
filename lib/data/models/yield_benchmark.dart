class YieldBenchmark {
  const YieldBenchmark({
    required this.cropType,
    required this.cropTypeBn,
    required this.defaultYieldPerDecKg,
    required this.defaultPricePerKgBdt,
    required this.defaultCostPerDecBdt,
    this.unit = 'kg',
    this.note = '',
    this.isOrchard = false,
  });

  final String cropType;
  final String cropTypeBn;
  final double defaultYieldPerDecKg;
  final double defaultPricePerKgBdt;
  final double defaultCostPerDecBdt;
  final String unit;
  final String note;
  final bool isOrchard;

  /// Conversions: 1 Mond (মন) = 40 Kg
  double get defaultYieldPerDecMond => defaultYieldPerDecKg / 40.0;
  double get defaultPricePerMondBdt => defaultPricePerKgBdt * 40.0;

  static const List<YieldBenchmark> presets = [
    YieldBenchmark(
      cropType: 'Boro Rice',
      cropTypeBn: 'বোরো ধান',
      defaultYieldPerDecKg: 28.0, // ~0.7 Mond per decimal
      defaultPricePerKgBdt: 32.0, // ~1,280 BDT / Mond
      defaultCostPerDecBdt: 600.0,
      note: 'High yield irrigated season rice (বোরো ধান).',
    ),
    YieldBenchmark(
      cropType: 'Aman Rice',
      cropTypeBn: 'আমন ধান',
      defaultYieldPerDecKg: 22.0, // ~0.55 Mond per decimal
      defaultPricePerKgBdt: 30.0, // ~1,200 BDT / Mond
      defaultCostPerDecBdt: 500.0,
      note: 'Rainfed monsoon season rice (আমন ধান).',
    ),
    YieldBenchmark(
      cropType: 'Potato',
      cropTypeBn: 'আলু',
      defaultYieldPerDecKg: 100.0, // ~2.5 Mond per decimal
      defaultPricePerKgBdt: 28.0,
      defaultCostPerDecBdt: 1200.0,
      note: 'High productivity tuber crop (আলু).',
    ),
    YieldBenchmark(
      cropType: 'Tomato',
      cropTypeBn: 'টমেটো',
      defaultYieldPerDecKg: 120.0, // ~3.0 Mond per decimal
      defaultPricePerKgBdt: 35.0,
      defaultCostPerDecBdt: 1500.0,
      note: 'High value vegetable crop (টমেটো).',
    ),
    YieldBenchmark(
      cropType: 'Wheat',
      cropTypeBn: 'গম',
      defaultYieldPerDecKg: 20.0, // ~0.5 Mond per decimal
      defaultPricePerKgBdt: 36.0,
      defaultCostPerDecBdt: 550.0,
      note: 'Rabi season grain crop (গম).',
    ),
    YieldBenchmark(
      cropType: 'Jute',
      cropTypeBn: 'পাট',
      defaultYieldPerDecKg: 15.0, // ~0.38 Mond per decimal
      defaultPricePerKgBdt: 65.0, // ~2,600 BDT / Mond
      defaultCostPerDecBdt: 600.0,
      note: 'Golden fiber cash crop (পাট).',
    ),
    YieldBenchmark(
      cropType: 'Mango',
      cropTypeBn: 'আম (বাগান)',
      defaultYieldPerDecKg: 180.0, // per orchard tree
      defaultPricePerKgBdt: 80.0,
      defaultCostPerDecBdt: 1000.0,
      isOrchard: true,
      note: 'Yield per orchard tree in Kg (আম).',
    ),
    YieldBenchmark(
      cropType: 'Custom Crop',
      cropTypeBn: 'অন্যান্য ফসল',
      defaultYieldPerDecKg: 25.0,
      defaultPricePerKgBdt: 35.0,
      defaultCostPerDecBdt: 600.0,
      note: 'Enter custom yield and prices.',
    ),
  ];
}
