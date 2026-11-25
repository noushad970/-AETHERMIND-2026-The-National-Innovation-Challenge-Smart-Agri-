class YieldCalculationResult {
  const YieldCalculationResult({
    required this.totalYieldKg,
    required this.totalYieldMond,
    required this.grossRevenueBdt,
    required this.totalCostBdt,
    required this.netProfitBdt,
    required this.roiPercent,
    required this.profitMarginPercent,
    required this.revenuePerDecimalBdt,
    required this.costPerDecimalBdt,
    required this.profitPerMondBdt,
    required this.isProfitable,
  });

  final double totalYieldKg;
  final double totalYieldMond;
  final double grossRevenueBdt;
  final double totalCostBdt;
  final double netProfitBdt;
  final double roiPercent;
  final double profitMarginPercent;
  final double revenuePerDecimalBdt;
  final double costPerDecimalBdt;
  final double profitPerMondBdt;
  final bool isProfitable;
}

class YieldCalculator {
  YieldCalculator._();

  /// Perform financial and yield calculations for a given land scale,
  /// expected yield per unit, selling price, and input costs.
  static YieldCalculationResult calculate({
    required double landAreaDecimal,
    required double yieldPerDecimalKg,
    required double pricePerKgBdt,
    required double seedCost,
    required double fertilizerCost,
    required double pesticideCost,
    required double irrigationCost,
    required double laborCost,
  }) {
    final area = landAreaDecimal <= 0 ? 1.0 : landAreaDecimal;
    final totalYieldKg = area * (yieldPerDecimalKg < 0 ? 0 : yieldPerDecimalKg);
    final totalYieldMond = totalYieldKg / 40.0;

    final grossRevenue = totalYieldKg * (pricePerKgBdt < 0 ? 0 : pricePerKgBdt);
    final totalCost = seedCost + fertilizerCost + pesticideCost + irrigationCost + laborCost;
    final netProfit = grossRevenue - totalCost;
    final isProfitable = netProfit >= 0;

    final roi = totalCost > 0 ? (netProfit / totalCost) * 100.0 : 0.0;
    final margin = grossRevenue > 0 ? (netProfit / grossRevenue) * 100.0 : 0.0;

    final revPerDec = area > 0 ? grossRevenue / area : 0.0;
    final costPerDec = area > 0 ? totalCost / area : 0.0;
    final profitPerMond = totalYieldMond > 0 ? netProfit / totalYieldMond : 0.0;

    return YieldCalculationResult(
      totalYieldKg: totalYieldKg,
      totalYieldMond: totalYieldMond,
      grossRevenueBdt: grossRevenue,
      totalCostBdt: totalCost,
      netProfitBdt: netProfit,
      roiPercent: roi,
      profitMarginPercent: margin,
      revenuePerDecimalBdt: revPerDec,
      costPerDecimalBdt: costPerDec,
      profitPerMondBdt: profitPerMond,
      isProfitable: isProfitable,
    );
  }
}
