import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/layout/desktop_scope.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/agri_atmospheric_background.dart';
import '../../../../core/widgets/auth_gate.dart';
import '../../../../core/widgets/live_pulse_badge.dart';
import '../../../../data/models/fish_activity.dart';
import '../../../../data/models/fish_daily_suggestion.dart';
import '../../../../data/models/fish_daily_summary.dart';
import '../../../../data/models/fish_pond.dart';
import '../../../../data/services/feeding_alarm_service.dart';
import '../providers/fish_daily_suggestions_provider.dart';
import '../providers/fish_provider.dart';

class FishLiveTrackScreen extends StatefulWidget {
  const FishLiveTrackScreen({super.key, required this.pondId});
  final String pondId;

  @override
  State<FishLiveTrackScreen> createState() => _FishLiveTrackScreenState();
}

class _FishLiveTrackScreenState extends State<FishLiveTrackScreen> {
  bool _bound = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_bound) {
      context.read<FishProvider>().bindPond(widget.pondId);
      _bound = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBn = context.isBn;
    final fishProv = context.watch<FishProvider>();
    final pond = fishProv.getPond(widget.pondId);

    if (pond == null) {
      return Scaffold(
        appBar: AppBar(title: Text(isBn ? 'পুকুর ট্র্যাকার' : 'Fish Tracker')),
        body: Center(
          child: Text(
            isBn ? 'পুকুরের তথ্য পাওয়া যায়নি।' : 'Pond records not found.',
          ),
        ),
      );
    }

    final activities = fishProv.getActivities(pond.id);
    final summaries = fishProv.getSummaries(pond.id);
    final todaySummary = summaries.isNotEmpty ? summaries.first : null;

    final suggestionsProv = context.watch<FishDailySuggestionsProvider>();
    suggestionsProv.primeFromCache(pond.id);
    final suggestion = suggestionsProv.suggestionFor(pond.id);

    return AuthGate(
      featureName: isBn ? 'মৎস্য লাইভ ট্র্যাকিং' : 'Fish Live Tracking',
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.water_rounded, color: Color(0xFF00897B), size: 22),
              const SizedBox(width: 8),
              Text(
                pond.pondName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.alarm_on_rounded),
              tooltip: isBn ? 'খাবারের অ্যালার্ম' : 'Feeding Alarm',
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.settings),
            ),
            IconButton(
              icon: const Icon(Icons.edit_note_rounded),
              tooltip: isBn ? 'দৈনিক হিসাব লিখুন' : 'Log Daily Metrics',
              onPressed: () => _showLogMetricsModal(context, pond, todaySummary),
            ),
          ],
        ),
        body: AgriAtmosphericBackground(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Hero Live Header Banner
              _FishHeroLiveBanner(pond: pond, isBn: isBn),
              const SizedBox(height: 16),

              // Live Stats Grid
              _FishStatsGrid(
                pond: pond,
                activities: activities,
                todaySummary: todaySummary,
                isBn: isBn,
              ),
              const SizedBox(height: 16),

              // Swimming & Dissolved Oxygen Card
              _PondOxygenSwimmingCard(
                pond: pond,
                todaySummary: todaySummary,
                isBn: isBn,
                onToggleAeration: (done) async {
                  final now = DateTime.now();
                  final summary = FishDailySummary(
                    id: '${pond.id}_${now.year}_${now.month}_${now.day}',
                    fishPondId: pond.id,
                    date: now,
                    feedGivenKg: todaySummary?.feedGivenKg ?? 0.0,
                    waterTempC: todaySummary?.waterTempC ?? 28.0,
                    dissolvedOxygenPpm: done ? 6.5 : (todaySummary?.dissolvedOxygenPpm ?? 5.5),
                    deadCount: todaySummary?.deadCount ?? 0,
                    swimmingAerationDone: done,
                  );
                  await context.read<FishProvider>().recordDailySummary(summary);
                },
              ),
              const SizedBox(height: 16),

              // AI Daily Suggestion Card with Bangla TTS Voice Reading
              _AiFishSuggestionCard(
                pond: pond,
                suggestion: suggestion,
                todaySummary: todaySummary,
                isBn: isBn,
              ),
              const SizedBox(height: 16),

              // Fish Feeding Alarm Card
              const _FishLiveFeedingAlarmCard(),
              const SizedBox(height: 16),

              // Today's Feeding & Pond Care Schedule
              _TodayFishActivitiesCard(
                pond: pond,
                activities: activities,
                isBn: isBn,
              ),
              const SizedBox(height: 16),

              // Culture Milestones & Harvest Roadmap
              _FishRoadmapCard(
                pond: pond,
                activities: activities,
                isBn: isBn,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogMetricsModal(
    BuildContext context,
    FishPond pond,
    FishDailySummary? currentSummary,
  ) {
    final isBn = context.read<LocaleProvider>().isBangla;
    final feedCtrl = TextEditingController(
      text: currentSummary?.feedGivenKg != null && currentSummary!.feedGivenKg > 0
          ? '${currentSummary.feedGivenKg}'
          : '5.0',
    );
    final doCtrl = TextEditingController(
      text: '${currentSummary?.dissolvedOxygenPpm ?? 5.5}',
    );
    final tempCtrl = TextEditingController(
      text: '${currentSummary?.waterTempC ?? 28.0}',
    );
    final deadCtrl = TextEditingController(
      text: '${currentSummary?.deadCount ?? 0}',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isBn ? 'আজকের পুকুরের পরিমাপ ও তথ্য' : 'Log Today\'s Pond Metrics',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: feedCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: isBn ? 'খাবার প্রদান (কেজি)' : 'Feed Given (kg)',
                        prefixIcon: const Icon(Icons.restaurant_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: doCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: isBn ? 'অক্সিজেন (ppm)' : 'Oxygen (ppm)',
                        prefixIcon: const Icon(Icons.air_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: tempCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: isBn ? 'পানির তাপমাত্রা (°C)' : 'Water Temp (°C)',
                        prefixIcon: const Icon(Icons.thermostat_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: deadCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: isBn ? 'মৃত মাছ (সংখ্যা)' : 'Dead Count',
                        prefixIcon: const Icon(Icons.heart_broken_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00695C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    final feed = double.tryParse(feedCtrl.text.trim()) ?? 0.0;
                    final oxy = double.tryParse(doCtrl.text.trim()) ?? 5.5;
                    final temp = double.tryParse(tempCtrl.text.trim()) ?? 28.0;
                    final dead = int.tryParse(deadCtrl.text.trim()) ?? 0;

                    final now = DateTime.now();
                    final summary = FishDailySummary(
                      id: '${pond.id}_${now.year}_${now.month}_${now.day}',
                      fishPondId: pond.id,
                      date: now,
                      feedGivenKg: feed,
                      waterTempC: temp,
                      dissolvedOxygenPpm: oxy,
                      deadCount: dead,
                      swimmingAerationDone: currentSummary?.swimmingAerationDone ?? false,
                    );

                    final fishProv = context.read<FishProvider>();

                    if (dead > 0 && dead != pond.deadCount) {
                      pond.deadCount += dead;
                      await fishProv.updatePond(pond);
                    }

                    await fishProv.recordDailySummary(summary);
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  },
                  child: Text(
                    isBn ? 'সংরক্ষণ করুন' : 'Save Metrics',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FishHeroLiveBanner extends StatelessWidget {
  const _FishHeroLiveBanner({required this.pond, required this.isBn});
  final FishPond pond;
  final bool isBn;

  @override
  Widget build(BuildContext context) {
    final species = pond.speciesData;
    final progress = (pond.progress * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF004D40), Color(0xFF00695C), Color(0xFF00897B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF004D40).withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.set_meal_rounded, color: AppTheme.sunYellow, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      isBn ? species.nameBn : species.nameEn,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const LivePulseBadge(label: 'Pond Live', color: Color(0xFF80CBC4)),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            pond.pondName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isBn
                ? 'পুকুরের আকার: ${pond.pondAreaDecimals} শতক • গভীরতা: ${pond.waterDepthFeet} ফুট'
                : 'Pond Size: ${pond.pondAreaDecimals} dec • Depth: ${pond.waterDepthFeet} ft',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isBn ? 'চাষের অগ্রগতি' : 'Culture Progress',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
              Text(
                '$progress%',
                style: const TextStyle(
                  color: AppTheme.sunYellow,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pond.progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.sunYellow),
            ),
          ),
        ],
      ),
    );
  }
}

class _FishStatsGrid extends StatelessWidget {
  const _FishStatsGrid({
    required this.pond,
    required this.activities,
    required this.todaySummary,
    required this.isBn,
  });

  final FishPond pond;
  final List<FishActivity> activities;
  final FishDailySummary? todaySummary;
  final bool isBn;

  @override
  Widget build(BuildContext context) {
    final completed = activities.where((a) => a.isCompleted).length;
    final total = activities.length;

    return GridView.count(
      crossAxisCount: DesktopScope.of(context) ? 4 : 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: [
        _StatCard(
          title: isBn ? 'চাষের বয়স' : 'Culture Days',
          value: '${pond.daysSinceStocking}',
          subtitle: isBn ? 'মোট ${pond.targetHarvestDays} দিন' : 'of ${pond.targetHarvestDays} days',
          icon: Icons.calendar_today_rounded,
          color: const Color(0xFF00695C),
        ),
        _StatCard(
          title: isBn ? 'আহরণের বাকি' : 'Days to Harvest',
          value: '${pond.daysUntilHarvest}',
          subtitle: isBn ? 'সম্ভাব্য তারিখ' : 'Est. Harvest',
          icon: Icons.timer_outlined,
          color: const Color(0xFF0277BD),
        ),
        _StatCard(
          title: isBn ? 'জীবিত মাছ' : 'Live Population',
          value: '${pond.liveCount}',
          subtitle: isBn ? 'মজুদ: ${pond.fingerlingCount}' : 'Stocked: ${pond.fingerlingCount}',
          icon: Icons.groups_rounded,
          color: const Color(0xFF1B7A5C),
        ),
        _StatCard(
          title: isBn ? 'সম্পন্ন কার্যক্রম' : 'Completed Tasks',
          value: '$completed / $total',
          subtitle: isBn ? 'দৈনিক ও পর্যায়ক্রমিক' : 'Scheduled Tasks',
          icon: Icons.task_alt_rounded,
          color: const Color(0xFFE65100),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(icon, color: color, size: 18),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _PondOxygenSwimmingCard extends StatelessWidget {
  const _PondOxygenSwimmingCard({
    required this.pond,
    required this.todaySummary,
    required this.isBn,
    required this.onToggleAeration,
  });

  final FishPond pond;
  final FishDailySummary? todaySummary;
  final bool isBn;
  final ValueChanged<bool> onToggleAeration;

  @override
  Widget build(BuildContext context) {
    final species = pond.speciesData;
    final isDone = todaySummary?.swimmingAerationDone ?? false;
    final oxygenLevel = todaySummary?.dissolvedOxygenPpm ?? (isDone ? 6.5 : 5.2);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF00897B).withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00897B).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.pool_rounded, color: Color(0xFF00897B), size: 22),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isBn ? 'সাঁতার ও অক্সিজেন সঞ্চালন' : 'Swimming & Oxygen Aeration',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'DO: ${oxygenLevel.toStringAsFixed(1)} ppm (Min > ${species.minOxygenPpm} ppm)',
                        style: TextStyle(
                          color: oxygenLevel >= species.minOxygenPpm
                              ? AppTheme.primaryGreen
                              : AppTheme.danger,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Switch.adaptive(
                value: isDone,
                activeTrackColor: const Color(0xFF00897B),
                onChanged: onToggleAeration,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF00897B).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF00897B), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isBn
                        ? species.swimmingAerationAdviceBn
                        : 'Agitate surface water by swimming in the pond or using bamboo poles to spread dissolved oxygen.',
                    style: const TextStyle(fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AiFishSuggestionCard extends StatelessWidget {
  const _AiFishSuggestionCard({
    required this.pond,
    required this.suggestion,
    required this.todaySummary,
    required this.isBn,
  });

  final FishPond pond;
  final FishDailySuggestion? suggestion;
  final FishDailySummary? todaySummary;
  final bool isBn;

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<FishDailySuggestionsProvider>();
    final isLoading = prov.isLoading(pond.id);

    final guidanceText = suggestion != null
        ? (isBn ? suggestion!.feedingGuidanceBn : suggestion!.feedingGuidanceEn)
        : (isBn
            ? 'পুকুরের মাছকে সকাল ও বিকালে নির্ধারিত মাত্রায় খাবার দিন এবং দ্রবীভূত অক্সিজেন ৫ পিপিএম এর উপরে বজায় রাখুন।'
            : 'Feed measured portions morning and afternoon and ensure dissolved oxygen remains above 5 ppm.');

    final oxygenAdvice = suggestion != null
        ? (isBn ? suggestion!.oxygenAerationAdviceBn : suggestion!.oxygenAerationAdviceEn)
        : pond.speciesData.swimmingAerationAdviceBn;

    final doItems = suggestion?.doItems ?? [
      'সকাল ৮:০০ ও বিকাল ৪:৩০ টায় সুষম খাবার দিন',
      'পুকুরে সাঁতার কেটে বা বাঁশ পিটিয়ে অক্সিজেন বাড়ান',
    ];
    final dontItems = suggestion?.dontItems ?? [
      'মেঘলা দিনে বা বৃষ্টিতে অতিরিক্ত খাবার ফেলবেন না',
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF0288D1).withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0288D1).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.psychology_rounded, color: Color(0xFF0288D1), size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isBn ? 'দৈনিক এআই মৎস্য বিশেষজ্ঞ পরামর্শ' : 'Daily AI Aquaculture Advice',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0288D1).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            suggestion?.source ?? 'Gemini 3.5 AI',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0288D1),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
                onPressed: isLoading
                    ? null
                    : () => prov.refreshFor(pond, todaySummary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            guidanceText,
            style: const TextStyle(fontSize: 14, height: 1.45),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF00897B).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.waves_rounded, size: 16, color: Color(0xFF00695C)),
                    const SizedBox(width: 6),
                    Text(
                      isBn ? 'অক্সিজেন ও পানি ব্যবস্থাপনা' : 'Oxygen & Water Tip',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00695C),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(oxygenAdvice, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            isBn ? 'আজ যা করবেন:' : 'Today\'s DOs:',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 6),
          for (final item in doItems) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle, size: 16, color: AppTheme.primaryGreen),
                const SizedBox(width: 6),
                Expanded(child: Text(item, style: const TextStyle(fontSize: 12))),
              ],
            ),
            const SizedBox(height: 4),
          ],
          if (dontItems.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              isBn ? 'যা করবেন না:' : 'Today\'s DONTs:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),
            for (final item in dontItems) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.cancel, size: 16, color: AppTheme.danger),
                  const SizedBox(width: 6),
                  Expanded(child: Text(item, style: const TextStyle(fontSize: 12))),
                ],
              ),
              const SizedBox(height: 4),
            ],
          ],
        ],
      ),
    );
  }
}

class _TodayFishActivitiesCard extends StatelessWidget {
  const _TodayFishActivitiesCard({
    required this.pond,
    required this.activities,
    required this.isBn,
  });

  final FishPond pond;
  final List<FishActivity> activities;
  final bool isBn;

  @override
  Widget build(BuildContext context) {
    final todayActs = activities.where((a) => a.isToday || a.isDueOrPast && !a.isCompleted).toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isBn ? 'আজকের খাবার ও পরিচর্যা রুটিন' : 'Today\'s Feeding & Care Routine',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF00695C).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${todayActs.length} ${isBn ? "টি কাজ" : "tasks"}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF00695C),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (todayActs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                isBn ? 'আজকের সকল পরিচর্যা কাজ সম্পন্ন হয়েছে!' : 'All care tasks completed for today!',
                style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
              ),
            )
          else
            for (final act in todayActs) ...[
              _ActivityCheckboxTile(pond: pond, activity: act, isBn: isBn),
              const Divider(height: 1),
            ],
        ],
      ),
    );
  }
}

class _ActivityCheckboxTile extends StatelessWidget {
  const _ActivityCheckboxTile({
    required this.pond,
    required this.activity,
    required this.isBn,
  });

  final FishPond pond;
  final FishActivity activity;
  final bool isBn;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      value: activity.isCompleted,
      activeColor: const Color(0xFF00695C),
      title: Text(
        isBn ? activity.titleBn : activity.title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          decoration: activity.isCompleted ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isBn ? activity.descriptionBn : activity.description,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              const Icon(Icons.access_time, size: 12, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(
                activity.suggestedTime,
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ],
      ),
      onChanged: (val) async {
        if (val == null) return;
        await context.read<FishProvider>().toggleActivity(
          pond.id,
          activity.id,
          val,
        );
      },
    );
  }
}

class _FishRoadmapCard extends StatelessWidget {
  const _FishRoadmapCard({
    required this.pond,
    required this.activities,
    required this.isBn,
  });

  final FishPond pond;
  final List<FishActivity> activities;
  final bool isBn;

  @override
  Widget build(BuildContext context) {
    final periodicActs = activities
        .where((a) => a.category == 'sampling' || a.category == 'treatment' || a.dayFromStocking % 20 == 0)
        .take(6)
        .toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isBn ? 'চাষের মাইলফলক ও বৃদ্ধির রোডম্যাপ' : 'Growth Milestones & Roadmap',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          for (final act in periodicActs) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(
                    act.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: act.isCompleted ? AppTheme.primaryGreen : Colors.grey,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${isBn ? "${act.dayFromStocking}তম দিন" : "Day ${act.dayFromStocking}"}: ${isBn ? act.titleBn : act.title}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FishLiveFeedingAlarmCard extends StatelessWidget {
  const _FishLiveFeedingAlarmCard();

  @override
  Widget build(BuildContext context) {
    final isBn = context.isBn;
    final alarmService = context.watch<FeedingAlarmService>();
    final isPlaying = alarmService.isPlayingAlarm;
    final isEnabled = alarmService.alarmsEnabled;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF00695C).withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00695C).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.alarm_on_rounded, color: Color(0xFF00695C), size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isBn ? '⏰ মাছের খাবার অ্যালার্ম (BST)' : '⏰ Fish Feed Alarm (BST)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      isBn
                          ? 'সকাল ০৮:০০ ও বিকাল ০৪:৩০ এ স্বয়ংক্রিয় অ্যালার্ম বাজবে'
                          : 'Rings automatically at 08:00 AM & 04:30 PM BST',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: isEnabled,
                activeTrackColor: const Color(0xFF00695C),
                onChanged: (val) async {
                  await alarmService.setAlarmsEnabled(val);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isPlaying) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              child: ElevatedButton.icon(
                onPressed: () async {
                  await alarmService.stopAlarmAudio();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.danger,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.stop_circle_rounded, size: 22),
                label: Text(
                  isBn ? '🚨 অ্যালার্ম বন্ধ করুন (Stop Alarm)' : '🚨 Stop Fish Alarm Sound Now',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ],
          Row(
            children: [
              Expanded(
                flex: 3,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await alarmService.testFishAlarmAudio(isBn: isBn);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF00695C),
                    side: const BorderSide(color: Color(0xFF00695C)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.volume_up_rounded, size: 18),
                  label: Text(
                    isBn ? 'অ্যালার্ম পরীক্ষা' : 'Test Alarm Sound',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await alarmService.stopAlarmAudio();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPlaying ? AppTheme.danger : Colors.red.shade50,
                    foregroundColor: isPlaying ? Colors.white : AppTheme.danger,
                    side: BorderSide(
                      color: isPlaying ? AppTheme.danger : AppTheme.danger.withValues(alpha: 0.4),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    elevation: isPlaying ? 2 : 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.stop_rounded, size: 18),
                  label: Text(
                    isBn ? 'বন্ধ করুন' : 'Stop Alarm',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
