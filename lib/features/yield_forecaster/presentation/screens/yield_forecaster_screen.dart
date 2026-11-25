import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/header_action_bar.dart';
import '../../../../data/models/yield_benchmark.dart';
import '../../../../data/services/yield_calculator.dart';

class YieldForecasterScreen extends StatefulWidget {
  const YieldForecasterScreen({super.key});

  @override
  State<YieldForecasterScreen> createState() => _YieldForecasterScreenState();
}

class _YieldForecasterScreenState extends State<YieldForecasterScreen> {
  YieldBenchmark _selectedPreset = YieldBenchmark.presets.first;

  late TextEditingController _landAreaController;
  late TextEditingController _yieldController;
  late TextEditingController _priceController;

  late TextEditingController _seedCostController;
  late TextEditingController _fertilizerCostController;
  late TextEditingController _pesticideCostController;
  late TextEditingController _irrigationCostController;
  late TextEditingController _laborCostController;

  @override
  void initState() {
    super.initState();
    _landAreaController = TextEditingController(text: '10');
    _yieldController = TextEditingController(
      text: _selectedPreset.defaultYieldPerDecKg.toStringAsFixed(0),
    );
    _priceController = TextEditingController(
      text: _selectedPreset.defaultPricePerKgBdt.toStringAsFixed(0),
    );

    final baseCost = _selectedPreset.defaultCostPerDecBdt * 10;
    _seedCostController = TextEditingController(text: (baseCost * 0.2).toStringAsFixed(0));
    _fertilizerCostController = TextEditingController(text: (baseCost * 0.3).toStringAsFixed(0));
    _pesticideCostController = TextEditingController(text: (baseCost * 0.15).toStringAsFixed(0));
    _irrigationCostController = TextEditingController(text: (baseCost * 0.15).toStringAsFixed(0));
    _laborCostController = TextEditingController(text: (baseCost * 0.2).toStringAsFixed(0));
  }

  @override
  void dispose() {
    _landAreaController.dispose();
    _yieldController.dispose();
    _priceController.dispose();
    _seedCostController.dispose();
    _fertilizerCostController.dispose();
    _pesticideCostController.dispose();
    _irrigationCostController.dispose();
    _laborCostController.dispose();
    super.dispose();
  }

  void _applyPreset(YieldBenchmark preset) {
    setState(() {
      _selectedPreset = preset;
      _yieldController.text = preset.defaultYieldPerDecKg.toStringAsFixed(0);
      _priceController.text = preset.defaultPricePerKgBdt.toStringAsFixed(0);

      final landArea = double.tryParse(_landAreaController.text) ?? 10.0;
      final totalCost = preset.defaultCostPerDecBdt * landArea;

      _seedCostController.text = (totalCost * 0.2).toStringAsFixed(0);
      _fertilizerCostController.text = (totalCost * 0.3).toStringAsFixed(0);
      _pesticideCostController.text = (totalCost * 0.15).toStringAsFixed(0);
      _irrigationCostController.text = (totalCost * 0.15).toStringAsFixed(0);
      _laborCostController.text = (totalCost * 0.2).toStringAsFixed(0);
    });
  }

  void _recalculateCostsForLandArea(double newLandArea) {
    final totalCost = _selectedPreset.defaultCostPerDecBdt * newLandArea;
    setState(() {
      _seedCostController.text = (totalCost * 0.2).toStringAsFixed(0);
      _fertilizerCostController.text = (totalCost * 0.3).toStringAsFixed(0);
      _pesticideCostController.text = (totalCost * 0.15).toStringAsFixed(0);
      _irrigationCostController.text = (totalCost * 0.15).toStringAsFixed(0);
      _laborCostController.text = (totalCost * 0.2).toStringAsFixed(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final landArea = double.tryParse(_landAreaController.text) ?? 0.0;
    final yieldPerDec = double.tryParse(_yieldController.text) ?? 0.0;
    final pricePerKg = double.tryParse(_priceController.text) ?? 0.0;

    final seedCost = double.tryParse(_seedCostController.text) ?? 0.0;
    final fertilizerCost = double.tryParse(_fertilizerCostController.text) ?? 0.0;
    final pesticideCost = double.tryParse(_pesticideCostController.text) ?? 0.0;
    final irrigationCost = double.tryParse(_irrigationCostController.text) ?? 0.0;
    final laborCost = double.tryParse(_laborCostController.text) ?? 0.0;

    final result = YieldCalculator.calculate(
      landAreaDecimal: landArea,
      yieldPerDecimalKg: yieldPerDec,
      pricePerKgBdt: pricePerKg,
      seedCost: seedCost,
      fertilizerCost: fertilizerCost,
      pesticideCost: pesticideCost,
      irrigationCost: irrigationCost,
      laborCost: laborCost,
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/app_logo.png',
              width: 26,
              height: 26,
              errorBuilder: (_, _, _) => const Icon(Icons.calculate_outlined, size: 22),
            ),
            const SizedBox(width: 8),
            Text(
              context.tr(
                AppStrings.yieldForecaster,
                AppStrings.yieldForecasterBn,
              ),
            ),
          ],
        ),
        actions: const [
          HeaderActionBar(),
          SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreenLight.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: AppTheme.primaryGreen,
                    child: Icon(Icons.calculate, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr(
                            AppStrings.yieldForecasterTitle,
                            AppStrings.yieldForecasterTitleBn,
                          ),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.tr(
                            'Estimate harvest, total expenditure, revenue & net profit.',
                            'ফলন, সম্ভাব্য ব্যয়, মোট আয় ও লাভ-ক্ষতির পূর্বাভাস হিসাব করুন।',
                          ),
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _ForecastResultCard(result: result, landArea: landArea),
            const SizedBox(height: 20),

            Text(
              context.tr(
                AppStrings.selectCropPreset,
                AppStrings.selectCropPresetBn,
              ),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: YieldBenchmark.presets.map((preset) {
                  final isSelected = _selectedPreset.cropType == preset.cropType;
                  final label = context.isBn
                      ? preset.cropTypeBn
                      : preset.cropType;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: isSelected,
                      selectedColor: AppTheme.primaryGreen,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (_) => _applyPreset(preset),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.landscape, color: AppTheme.primaryGreen),
                        const SizedBox(width: 8),
                        Text(
                          context.tr(
                            'Land Scale & Yield Expected',
                            'জমির পরিমাণ ও প্রত্যাশিত ফলন',
                          ),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    TextFormField(
                      controller: _landAreaController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (val) {
                        final area = double.tryParse(val);
                        if (area != null && area > 0) {
                          _recalculateCostsForLandArea(area);
                        } else {
                          setState(() {});
                        }
                      },
                      decoration: InputDecoration(
                        labelText: context.tr(
                          AppStrings.landAreaDecimal,
                          AppStrings.landAreaDecimalBn,
                        ),
                        helperText: context.tr(
                          '1 decimal ≈ 40.47 m²',
                          '১ শতক ≈ ৪০.৪৭ বর্গমিটার',
                        ),
                        suffixText: context.tr('dec', 'শতক'),
                        prefixIcon: const Icon(Icons.aspect_ratio),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _yieldController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: context.tr(
                          AppStrings.expectedYieldPerDec,
                          AppStrings.expectedYieldPerDecBn,
                        ),
                        helperText: context.tr(
                          'Equivalent to ${(yieldPerDec / 40.0).toStringAsFixed(2)} Mond / dec',
                          'শতকে প্রায় ${(yieldPerDec / 40.0).toStringAsFixed(2)} মণ',
                        ),
                        suffixText: context.tr('kg/dec', 'কেজি/শতক'),
                        prefixIcon: const Icon(Icons.scale),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: context.tr(
                          AppStrings.sellingPricePerKg,
                          AppStrings.sellingPricePerKgBn,
                        ),
                        helperText: context.tr(
                          'Equivalent to ৳${(pricePerKg * 40.0).toStringAsFixed(0)} / Mond',
                          'মণ প্রতি ৳${(pricePerKg * 40.0).toStringAsFixed(0)}',
                        ),
                        prefixText: '৳ ',
                        suffixText: context.tr('BDT/kg', 'টাকা/কেজি'),
                        prefixIcon: const Icon(Icons.sell_outlined),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.receipt_long, color: AppTheme.earthBrown),
                        const SizedBox(width: 8),
                        Text(
                          context.tr(
                            'Production Input Costs (BDT / ৳)',
                            'উৎপাদন ব্যয় / খরচ (টাকা)',
                          ),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    _CostInputField(
                      controller: _seedCostController,
                      label: context.tr(AppStrings.seedCost, AppStrings.seedCostBn),
                      icon: Icons.spa_outlined,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),

                    _CostInputField(
                      controller: _fertilizerCostController,
                      label: context.tr(AppStrings.fertilizerCost, AppStrings.fertilizerCostBn),
                      icon: Icons.science_outlined,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),

                    _CostInputField(
                      controller: _pesticideCostController,
                      label: context.tr(AppStrings.pesticideCost, AppStrings.pesticideCostBn),
                      icon: Icons.bug_report_outlined,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),

                    _CostInputField(
                      controller: _irrigationCostController,
                      label: context.tr(AppStrings.irrigationCost, AppStrings.irrigationCostBn),
                      icon: Icons.water_drop_outlined,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),

                    _CostInputField(
                      controller: _laborCostController,
                      label: context.tr(AppStrings.laborCost, AppStrings.laborCostBn),
                      icon: Icons.groups_outlined,
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            _FinancialBreakdownTable(result: result, landArea: landArea),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _ForecastResultCard extends StatelessWidget {
  const _ForecastResultCard({required this.result, required this.landArea});

  final YieldCalculationResult result;
  final double landArea;

  @override
  Widget build(BuildContext context) {
    final isProfit = result.isProfitable;
    final primaryColor = isProfit ? AppTheme.primaryGreen : AppTheme.danger;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: primaryColor,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isProfit ? Icons.trending_up : Icons.trending_down,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  isProfit
                      ? context.tr(
                          AppStrings.projectedNetProfit,
                          AppStrings.projectedNetProfitBn,
                        )
                      : context.tr(
                          AppStrings.projectedNetLoss,
                          AppStrings.projectedNetLossBn,
                        ),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${result.roiPercent >= 0 ? '+' : ''}${result.roiPercent.toStringAsFixed(1)}% ROI',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '৳ ${result.netProfitBdt.abs().toStringAsFixed(0)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${context.tr("Margin", "মার্জিন")}: ${result.profitMarginPercent.toStringAsFixed(1)}% | ${context.tr("Land", "জমি")}: ${landArea.toStringAsFixed(1)} ${context.tr("dec", "শতক")}',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),

            const Divider(color: Colors.white38, height: 24),

            Row(
              children: [
                Expanded(
                  child: _MiniResultTile(
                    title: context.tr('Total Harvest', 'মোট ফলন'),
                    value:
                        '${result.totalYieldMond.toStringAsFixed(1)} ${context.tr("Mond", "মণ")}\n(${result.totalYieldKg.toStringAsFixed(0)} ${context.tr("kg", "কেজি")})',
                  ),
                ),
                Expanded(
                  child: _MiniResultTile(
                    title: context.tr('Gross Revenue', 'মোট বিক্রয়মূল্য'),
                    value: '৳ ${result.grossRevenueBdt.toStringAsFixed(0)}',
                  ),
                ),
                Expanded(
                  child: _MiniResultTile(
                    title: context.tr('Input Cost', 'মোট খরচ'),
                    value: '৳ ${result.totalCostBdt.toStringAsFixed(0)}',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniResultTile extends StatelessWidget {
  const _MiniResultTile({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _CostInputField extends StatelessWidget {
  const _CostInputField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixText: '৳ ',
        prefixIcon: Icon(icon, size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}

class _FinancialBreakdownTable extends StatelessWidget {
  const _FinancialBreakdownTable({required this.result, required this.landArea});

  final YieldCalculationResult result;
  final double landArea;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr(
                'Per Decimal Breakdown Analysis',
                'শতক প্রতি বিস্তারিত আয়-ব্যয় বিশ্লেষণ',
              ),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _BreakdownRow(
              label: context.tr('Revenue per Decimal', 'শতক প্রতি আয় (৳/শতক)'),
              value: '৳ ${result.revenuePerDecimalBdt.toStringAsFixed(1)}',
            ),
            const Divider(),
            _BreakdownRow(
              label: context.tr('Cost per Decimal', 'শতক প্রতি খরচ (৳/শতক)'),
              value: '৳ ${result.costPerDecimalBdt.toStringAsFixed(1)}',
            ),
            const Divider(),
            _BreakdownRow(
              label: context.tr('Net Profit per Decimal', 'শতক প্রতি নিট লাভ (৳/শতক)'),
              value: '৳ ${(result.netProfitBdt / (landArea <= 0 ? 1 : landArea)).toStringAsFixed(1)}',
              isBold: true,
            ),
            const Divider(),
            _BreakdownRow(
              label: context.tr('Profit per Mond harvested', 'মণ প্রতি লাভ (৳/মন)'),
              value: '৳ ${result.profitPerMondBdt.toStringAsFixed(1)}',
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  final String label;
  final String value;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? AppTheme.primaryGreen : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
