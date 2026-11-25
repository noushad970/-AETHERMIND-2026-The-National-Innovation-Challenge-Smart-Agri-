import '../models/soil_type.dart';

enum IrrigationDecision {
  noIrrigationRainExpected,
  lightIrrigationNeeded,
  fullIrrigationNeeded,
}

class IrrigationCalculationResult {
  const IrrigationCalculationResult({
    required this.grossWaterMm,
    required this.effectiveRainMm,
    required this.netWaterMm,
    required this.litersPerDecimal,
    required this.totalLiters,
    required this.pumpRuntimeMinutes,
    required this.recommendedIntervalDays,
    required this.decision,
    required this.decisionMessage,
    required this.decisionMessageBn,
  });

  final double grossWaterMm;
  final double effectiveRainMm;
  final double netWaterMm;
  final double litersPerDecimal;
  final double totalLiters;
  final double pumpRuntimeMinutes;
  final int recommendedIntervalDays;
  final IrrigationDecision decision;
  final String decisionMessage;
  final String decisionMessageBn;
}

class IrrigationCalculator {
  IrrigationCalculator._();

  /// Daily crop water requirements in mm/day
  static const Map<String, double> cropWaterNeeds = {
    'Paddy (ধান)': 6.5,
    'Potato (আলু)': 4.5,
    'Tomato (টমেটো)': 4.5,
    'Wheat (গম)': 3.5,
    'Vegetables (সবজি)': 4.0,
    'Orchard (বাগান)': 3.0,
    'Custom': 4.0,
  };

  static IrrigationCalculationResult calculate({
    required SoilType soilType,
    required String cropCategory,
    required double landAreaDecimal,
    required double expectedRainMm,
    double pumpFlowLitersPerMin = 100.0,
  }) {
    final area = landAreaDecimal <= 0 ? 1.0 : landAreaDecimal;
    final baseDailyWaterMm = cropWaterNeeds[cropCategory] ?? 4.0;

    // Soil moisture retention factor adjusts requirement
    // (Sandy soils require more frequent water, clay soils retain more)
    final soilRetentionFactor = (1.2 - (soilType.moistureRetentionFactor * 0.3));
    final grossWaterMm = baseDailyWaterMm * soilRetentionFactor;

    // Effective rain (80% of forecasted rainfall up to the gross requirement)
    final effectiveRainMm = (expectedRainMm * 0.8).clamp(0.0, grossWaterMm);

    // Net irrigation required
    final netWaterMm = (grossWaterMm - effectiveRainMm).clamp(0.0, 50.0);

    // 1 mm water on 1 decimal (40.47 m²) = 40.47 Liters
    final litersPerDecimal = netWaterMm * 40.47;
    final totalLiters = litersPerDecimal * area;

    // Pump runtime calculation (standard 1 HP pump ~ 100 L/min)
    final pumpRuntimeMinutes = totalLiters > 0 && pumpFlowLitersPerMin > 0
        ? totalLiters / pumpFlowLitersPerMin
        : 0.0;

    // Decision Logic
    IrrigationDecision decision;
    String decisionMsg;
    String decisionMsgBn;

    if (expectedRainMm >= grossWaterMm * 0.9) {
      decision = IrrigationDecision.noIrrigationRainExpected;
      decisionMsg = 'Hold Off Irrigation — Adequate Rain Expected';
      decisionMsgBn = 'সেচ স্থগিত রাখুন — পর্যাপ্ত বৃষ্টির সম্ভাবনা রয়েছে';
    } else if (netWaterMm < 1.5) {
      decision = IrrigationDecision.lightIrrigationNeeded;
      decisionMsg = 'Light Irrigation Needed — Soil is Adequately Moist';
      decisionMsgBn = 'হালকা সেচ প্রদান করুন — মাটি পর্যাপ্ত ভেজা রয়েছে';
    } else {
      decision = IrrigationDecision.fullIrrigationNeeded;
      decisionMsg = 'Full Irrigation Needed — Soil Moisture Deficit';
      decisionMsgBn = 'পরিকল্পিত সেচ প্রদান করুন — মাটির পানি ঘাটতি রয়েছে';
    }

    return IrrigationCalculationResult(
      grossWaterMm: grossWaterMm,
      effectiveRainMm: effectiveRainMm,
      netWaterMm: netWaterMm,
      litersPerDecimal: litersPerDecimal,
      totalLiters: totalLiters,
      pumpRuntimeMinutes: pumpRuntimeMinutes,
      recommendedIntervalDays: soilType.recommendedIntervalDays,
      decision: decision,
      decisionMessage: decisionMsg,
      decisionMessageBn: decisionMsgBn,
    );
  }
}
