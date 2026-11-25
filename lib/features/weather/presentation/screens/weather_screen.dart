import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/layout/adaptive_two_pane.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/agri_atmospheric_background.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/header_action_bar.dart';
import '../../../../core/widgets/live_pulse_badge.dart';
import '../../../../data/models/weather_data.dart';
import '../providers/weather_daily_advice_provider.dart';
import '../providers/weather_provider.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WeatherProvider>().loadCurrentLocation();
      final w = context.read<WeatherDailyAdviceProvider>();
      if (!w.hasFreshTodayRecordCached()) {
        unawaited(w.ensureToday());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/app_logo.png',
              width: 26,
              height: 26,
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.wb_sunny_outlined, size: 22),
            ),
            const SizedBox(width: 8),
            Text(
              context.tr(AppStrings.weather, AppStrings.weatherBn),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: const [
          HeaderActionBar(),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Consumer<WeatherProvider>(
          builder: (context, prov, _) {
            if (prov.isLoading && !prov.hasData) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Center(child: CircularProgressIndicator()),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      context.tr(
                        'Detecting your agricultural location…',
                        'আপনার কৃষি খামারের অবস্থান শনাক্ত করা হচ্ছে…',
                      ),
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ),
                ],
              );
            }
            if (prov.error != null && !prov.hasData) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ErrorBanner(
                      message: prov.error!,
                      onRetry: () => prov.loadCurrentLocation(),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => prov.loadCurrentLocation(),
                          icon: const Icon(Icons.my_location),
                          label: Text(
                            context.tr(
                              'Detect my location',
                              'আমার অবস্থান শনাক্ত করুন',
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => prov.loadFallback(),
                          icon: const Icon(Icons.public),
                          label: Text(
                            context.tr(
                              'Use Dhaka, Bangladesh',
                              'ঢাকা, বাংলাদেশ ব্যবহার করুন',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }
            if (!prov.hasData) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    EmptyState(
                      title: context.tr(AppStrings.noData, AppStrings.noDataBn),
                      icon: Icons.wb_sunny_outlined,
                    ),
                  ],
                ),
              );
            }

            final w = prov.data!;
            final isRainy = w.precipitationMm > 0 ||
                w.conditionLabel.toLowerCase().contains('rain');

            return AgriAtmosphericBackground(
              isRainy: isRainy,
              child: RefreshIndicator(
                onRefresh: () => prov.loadCurrentLocation(),
                child: AdaptiveTwoPane(
                  primary: [
                    _CurrentWeatherHeroCard(w: w),
                    const SizedBox(height: 12),
                    _LocationActionsCard(
                      onDetect: () => prov.loadCurrentLocation(),
                      onFallback: () => prov.loadFallback(),
                    ),
                    const SizedBox(height: 12),
                    _RecommendationCard(w: w),
                    const SizedBox(height: 12),
                    _AiWeatherTipCard(weather: w),
                    const SizedBox(height: 16),
                  ],
                  secondary: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.tr(
                            AppStrings.todayForecast,
                            AppStrings.todayForecastBn,
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const LivePulseBadge(
                          label: '7-Day Forecast',
                          color: AppTheme.skyBlue,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _ForecastList(forecast: w.forecast),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CurrentWeatherHeroCard extends StatelessWidget {
  const _CurrentWeatherHeroCard({required this.w});
  final WeatherData w;

  @override
  Widget build(BuildContext context) {
    final isBn = context.isBn;
    final cond = isBn ? w.conditionLabelBn : w.conditionLabel;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0D47A1), // Sky
            const Color(0xFF0288D1),
            w.temperatureC > 30 ? const Color(0xFFE65100) : const Color(0xFF00695C),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0288D1).withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.place, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  w.locationName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _formatTimestamp(w.fetchedAt),
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${w.temperatureC.toStringAsFixed(1)}°C',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                    ),
                  ),
                  Text(
                    cond,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _weatherIconFor(w.conditionLabel),
                  size: 44,
                  color: AppTheme.sunYellow,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _WeatherPill(
                icon: Icons.thermostat,
                label:
                    '${context.tr("Feels", "অনুভূত")} ${w.feelsLikeC.toStringAsFixed(1)}°',
              ),
              _WeatherPill(
                icon: Icons.water_drop_outlined,
                label:
                    '${context.tr(AppStrings.humidity, AppStrings.humidityBn)} ${w.humidity}%',
              ),
              _WeatherPill(
                icon: Icons.air,
                label:
                    '${context.tr(AppStrings.windSpeed, AppStrings.windSpeedBn)} ${w.windSpeedKmh.toStringAsFixed(1)} km/h',
              ),
              _WeatherPill(
                icon: Icons.umbrella_outlined,
                label:
                    '${context.tr(AppStrings.rainfall, AppStrings.rainfallBn)} ${w.precipitationMm.toStringAsFixed(1)} mm',
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _weatherIconFor(String cond) {
    final lower = cond.toLowerCase();
    if (lower.contains('rain') || lower.contains('shower')) {
      return Icons.grain_rounded;
    }
    if (lower.contains('cloud')) {
      return Icons.cloud_rounded;
    }
    if (lower.contains('thunder')) {
      return Icons.flash_on_rounded;
    }
    return Icons.wb_sunny_rounded;
  }

  String _formatTimestamp(DateTime d) {
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}

class _WeatherPill extends StatelessWidget {
  const _WeatherPill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.w});
  final WeatherData w;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: AppTheme.primaryGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.eco, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('Farming Advisory', 'আজকের কৃষি পরামর্শ'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.isBn
                      ? (w.farmingRecommendationBn.isNotEmpty
                          ? w.farmingRecommendationBn
                          : w.farmingRecommendation)
                      : w.farmingRecommendation,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AiWeatherTipCard extends StatelessWidget {
  const _AiWeatherTipCard({required this.weather});
  final WeatherData weather;

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherDailyAdviceProvider>(
      builder: (context, prov, _) {
        final advice = prov.current;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF8E1), Color(0xFFFFFDE7)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.sunYellow),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppTheme.goldenHarvest),
                  const SizedBox(width: 8),
                  Text(
                    context.tr(
                      'AI Seasonal Field Tip',
                      'এআই মৌসুমী মাঠ পরামর্শ',
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFFE65100),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                advice != null
                    ? (advice.summary.isNotEmpty
                        ? advice.summary
                        : advice.headline)
                    : (context.isBn
                        ? 'আবহাওয়ার পরিবর্তনের দিকে লক্ষ্য রেখে জমিতে সেচ ও বালাইনাশক স্প্রে করুন।'
                        : 'Plan irrigation and pesticide spraying considering current weather trends.'),
                style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LocationActionsCard extends StatelessWidget {
  const _LocationActionsCard({
    required this.onDetect,
    required this.onFallback,
  });
  final VoidCallback onDetect;
  final VoidCallback onFallback;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onDetect,
            icon: const Icon(Icons.my_location, size: 16),
            label: Text(
              context.tr('Detect Location', 'অবস্থান শনাক্ত করুন'),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onFallback,
            icon: const Icon(Icons.location_city, size: 16),
            label: Text(
              context.tr('Dhaka HQ', 'ঢাকা সদর'),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}

class _ForecastList extends StatelessWidget {
  const _ForecastList({required this.forecast});
  final List<DailyForecast> forecast;

  @override
  Widget build(BuildContext context) {
    if (forecast.isEmpty) {
      return Center(
        child: Text(
          context.tr('No forecast available', 'কোনো পূর্বাভাস পাওয়া যায়নি'),
        ),
      );
    }

    return Column(
      children: [
        for (final day in forecast) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDay(day.date, context),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        context.isBn ? day.conditionLabelBn : day.conditionLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _iconForForecast(day.conditionLabel),
                  color: AppTheme.sunYellow,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${day.maxTempC.toStringAsFixed(0)}° / ${day.minTempC.toStringAsFixed(0)}°',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (day.precipitationMm > 0)
                      Text(
                        '💧 ${day.precipitationMm.toStringAsFixed(1)}mm',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.skyBlue,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  IconData _iconForForecast(String cond) {
    final lower = cond.toLowerCase();
    if (lower.contains('rain')) return Icons.grain;
    if (lower.contains('cloud')) return Icons.cloud;
    return Icons.wb_sunny;
  }

  String _formatDay(DateTime d, BuildContext context) {
    final now = DateTime.now();
    if (d.day == now.day && d.month == now.month) {
      return context.tr('Today', 'আজ');
    }
    return '${d.day}/${d.month}';
  }
}
