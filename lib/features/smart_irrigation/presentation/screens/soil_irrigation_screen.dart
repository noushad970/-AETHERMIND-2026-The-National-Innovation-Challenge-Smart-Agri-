import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/agri_atmospheric_background.dart';
import '../../../../core/widgets/agri_wave_water_gauge.dart';
import '../../../../core/widgets/header_action_bar.dart';
import '../../../../data/models/soil_type.dart';
import '../../../../data/services/irrigation_calculator.dart';
import '../../../../data/services/weather_service.dart';

class SoilIrrigationScreen extends StatefulWidget {
  const SoilIrrigationScreen({super.key});

  @override
  State<SoilIrrigationScreen> createState() => _SoilIrrigationScreenState();
}

class _SoilIrrigationScreenState extends State<SoilIrrigationScreen> {
  SoilType _selectedSoil = SoilType.presets[1]; // default Doash / Loam
  String _selectedCropCategory = 'Paddy (ধান)';

  late TextEditingController _landAreaController;
  late TextEditingController _rainController;
  bool _isFetchingWeather = false;

  final WeatherService _weatherService = WeatherService();

  @override
  void initState() {
    super.initState();
    _landAreaController = TextEditingController(text: '10');
    _rainController = TextEditingController(text: '0');
  }

  @override
  void dispose() {
    _landAreaController.dispose();
    _rainController.dispose();
    _weatherService.fetchWeather(lat: 0, lon: 0).ignore();
    super.dispose();
  }

  Future<void> _fetchLiveRain() async {
    setState(() => _isFetchingWeather = true);
    try {
      final pos = await _weatherService.getDeviceLocation().catchError(
            (_) => _weatherService.getDhakaFallback(),
          );
      final weather = await _weatherService.fetchWeather(
        lat: pos.latitude,
        lon: pos.longitude,
      );

      final rainSum = weather.precipitationMm;
      setState(() {
        _rainController.text = rainSum.toStringAsFixed(1);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${context.tr("Live rain forecast for", "বৃষ্টির পূর্বাভাস")} ${weather.locationName}: ${rainSum.toStringAsFixed(1)} mm',
          ),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr('Could not fetch live weather: $e', 'আবহাওয়া তথ্য পাওয়া যায়নি: $e'),
          ),
          backgroundColor: AppTheme.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isFetchingWeather = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final landArea = double.tryParse(_landAreaController.text) ?? 0.0;
    final expectedRain = double.tryParse(_rainController.text) ?? 0.0;

    final result = IrrigationCalculator.calculate(
      soilType: _selectedSoil,
      cropCategory: _selectedCropCategory,
      landAreaDecimal: landArea,
      expectedRainMm: expectedRain,
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
              errorBuilder: (_, _, _) => const Icon(Icons.water_drop_outlined, size: 22),
            ),
            const SizedBox(width: 8),
            Text(
              context.tr(
                AppStrings.smartIrrigation,
                AppStrings.smartIrrigationBn,
              ),
            ),
          ],
        ),
        actions: const [
          HeaderActionBar(),
          SizedBox(width: 8),
        ],
      ),
      body: AgriAtmosphericBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.skyBlue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.skyBlue.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: AppTheme.skyBlue,
                    child: Icon(Icons.water_drop, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr(
                            AppStrings.smartIrrigationTitle,
                            AppStrings.smartIrrigationTitleBn,
                          ),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.tr(
                            'Precise irrigation advice based on soil texture and rain forecast.',
                            'মাটির ধরণ ও বৃষ্টির পূর্বাভাসের ওপর ভিত্তি করে নিখুঁত সেচ পরামর্শ।',
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

            _IrrigationAdvisoryCard(result: result, landArea: landArea),
            const SizedBox(height: 20),

            Text(
              context.tr(
                AppStrings.selectSoilType,
                AppStrings.selectSoilTypeBn,
              ),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: SoilType.presets.map((soil) {
                  final isSelected = _selectedSoil.id == soil.id;
                  final label = context.isBn ? soil.nameBn : soil.name;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: isSelected,
                      selectedColor: AppTheme.skyBlue,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (_) => setState(() => _selectedSoil = soil),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppTheme.skyBlue, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${_selectedSoil.description} ${context.tr("Drainage", "পানি নিষ্কাশন")}: ${_selectedSoil.drainageRate}.',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ),
                ],
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
                        const Icon(Icons.eco_outlined, color: AppTheme.primaryGreen),
                        const SizedBox(width: 8),
                        Text(
                          context.tr('Crop & Field Parameters', 'ফসল ও জমির পরিমাপ'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    DropdownButtonFormField<String>(
                      initialValue: _selectedCropCategory,
                      decoration: InputDecoration(
                        labelText: context.tr('Select Crop Type', 'ফসলের ধরণ নির্বাচন করুন'),
                        prefixIcon: const Icon(Icons.grain),
                      ),
                      items: IrrigationCalculator.cropWaterNeeds.keys.map((crop) {
                        return DropdownMenuItem<String>(
                          value: crop,
                          child: Text(crop),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedCropCategory = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _landAreaController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: context.tr(
                          AppStrings.landAreaDecimal,
                          AppStrings.landAreaDecimalBn,
                        ),
                        suffixText: context.tr('dec', 'শতক'),
                        prefixIcon: const Icon(Icons.aspect_ratio),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _rainController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: context.tr(
                          AppStrings.expectedRainfall,
                          AppStrings.expectedRainfallBn,
                        ),
                        suffixText: 'mm',
                        prefixIcon: const Icon(Icons.cloudy_snowing),
                      ),
                    ),
                    const SizedBox(height: 12),

                    OutlinedButton.icon(
                      onPressed: _isFetchingWeather ? null : _fetchLiveRain,
                      icon: _isFetchingWeather
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location, size: 18),
                      label: Text(
                        _isFetchingWeather
                            ? context.tr('Fetching weather...', 'আবহাওয়া তথ্য লোড হচ্ছে...')
                            : context.tr(
                                AppStrings.fetchLiveRain,
                                AppStrings.fetchLiveRainBn,
                              ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.skyBlue,
                        side: const BorderSide(color: AppTheme.skyBlue),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      ),
    );
  }
}

class _IrrigationAdvisoryCard extends StatelessWidget {
  const _IrrigationAdvisoryCard({required this.result, required this.landArea});

  final IrrigationCalculationResult result;
  final double landArea;

  @override
  Widget build(BuildContext context) {
    Color cardColor;
    IconData decisionIcon;
    double moistureFraction;

    switch (result.decision) {
      case IrrigationDecision.noIrrigationRainExpected:
        cardColor = AppTheme.skyBlue;
        decisionIcon = Icons.umbrella;
        moistureFraction = 0.85;
        break;
      case IrrigationDecision.lightIrrigationNeeded:
        cardColor = AppTheme.sunYellow;
        decisionIcon = Icons.water_drop_outlined;
        moistureFraction = 0.50;
        break;
      case IrrigationDecision.fullIrrigationNeeded:
        cardColor = AppTheme.primaryGreen;
        decisionIcon = Icons.water_drop;
        moistureFraction = 0.25;
        break;
    }

    final message = context.isBn ? result.decisionMessageBn : result.decisionMessage;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cardColor.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(decisionIcon, color: Colors.white, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: AgriWaveWaterGauge(
              percentage: moistureFraction,
              size: 130,
              label: context.tr('Soil Water', 'মাটির রস'),
            ),
          ),
          const Divider(color: Colors.white38, height: 24),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('Total Water Volume', 'মোট পানির পরিমাণ'),
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${result.totalLiters.toStringAsFixed(0)} L',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '(${result.litersPerDecimal.toStringAsFixed(0)} L / ${context.tr("dec", "শতক")})',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                height: 45,
                width: 1,
                color: Colors.white38,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('1 HP Pump Runtime', '১ এইচপি পাম্প চলার সময়'),
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${result.pumpRuntimeMinutes.toStringAsFixed(0)} ${context.tr("Min", "মিনিট")}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${context.tr("Interval", "বিরতি")}: ${result.recommendedIntervalDays} ${context.tr("Days", "দিন")}',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
