import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/agri_atmospheric_background.dart';
import '../../../../core/widgets/auth_gate.dart';
import '../../../../core/widgets/header_action_bar.dart';
import '../../../../data/models/animal.dart';
import '../../../../data/models/livestock_daily_summary.dart';
import '../../../../data/models/livestock_daily_suggestion.dart';
import '../../../../data/repositories/livestock_repository.dart';
import '../providers/livestock_daily_suggestions_provider.dart';
import '../providers/livestock_provider.dart';

/// "Live Track" view for a single animal group. Mirrors the detail
/// screen but strips the form-heavy surfaces down to the things a
/// farmer actually wants at a glance while walking through the shed:
///
///   • live vs. total animal counts
///   • deaths recorded today / this week
///   • today's production (eggs or milk) if the species produces it
///   • 7-day mortality rate so a sudden spike is obvious
///   • a quick "record deaths" action so logging takes one tap
///
/// Everything is read from Firestore via [LivestockRepository] so the
/// screen stays in sync across devices.
class LivestockLiveTrackScreen extends StatefulWidget {
  const LivestockLiveTrackScreen({super.key, required this.animalId});
  final String animalId;

  @override
  State<LivestockLiveTrackScreen> createState() =>
      _LivestockLiveTrackScreenState();
}

class _LivestockLiveTrackScreenState extends State<LivestockLiveTrackScreen> {
  late final LivestockRepository _repo;
  // Bumped after any write so the page re-derives its stats from Firestore.
  int _version = 0;

  @override
  void initState() {
    super.initState();
    _repo = LivestockRepository();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LivestockProvider>().refreshFromCloud();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LivestockProvider>(
      builder: (context, prov, _) {
        final _ = _version;
        final animal = prov.byId(widget.animalId);
        if (animal == null) {
          return Scaffold(
            appBar: AppBar(
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/app_logo.png',
                    width: 26,
                    height: 26,
                    errorBuilder: (_, _, _) => const Icon(Icons.bolt, size: 22),
                  ),
                  const SizedBox(width: 8),
                  Text(context.tr(AppStrings.liveTrack, AppStrings.liveTrackBn)),
                ],
              ),
              actions: const [
                HeaderActionBar(),
                SizedBox(width: 8),
              ],
            ),
            body: Center(
              child: prov.isLoading
                  ? const CircularProgressIndicator()
                  : Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.pets_outlined,
                            size: 64,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            context.tr(
                              'Animal data is loading or record not found',
                              'প্রাণীর তথ্য লোড হচ্ছে বা খুঁজে পাওয়া যায়নি',
                            ),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => prov.refreshFromCloud(),
                            icon: const Icon(Icons.refresh),
                            label: Text(
                              context.tr('Refresh Data', 'পুনরায় লোড করুন'),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          );
        }
        return _Scaffold(
          animal: animal,
          repo: _repo,
          onMutated: () => setState(() => _version++),
        );
      },
    );
  }
}

class _Scaffold extends StatelessWidget {
  const _Scaffold({
    required this.animal,
    required this.repo,
    required this.onMutated,
  });

  final Animal animal;
  final LivestockRepository repo;
  final VoidCallback onMutated;

  Future<void> _recordDeaths(BuildContext context) async {
    final ctrl = TextEditingController(text: '0');
    final result = await showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.tr(AppStrings.recordDeaths, AppStrings.recordDeathsBn)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: context.tr('Deaths count', 'মৃত প্রাণীর সংখ্যা'),
            prefixIcon: const Icon(Icons.dangerous_outlined),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text(context.tr(AppStrings.cancel, AppStrings.cancelBn)),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, int.tryParse(ctrl.text.trim()) ?? 0),
            child: Text(context.tr(AppStrings.save, AppStrings.saveBn)),
          ),
        ],
      ),
    );
    if (result == null || result <= 0) return;
    if (!context.mounted) return;
    await context.read<LivestockProvider>().recordDeaths(animal.id, result);
    onMutated();
  }

  Future<void> _toggleActivity(
    BuildContext context,
    String activityId,
    bool done,
  ) async {
    await context.read<LivestockProvider>().toggleActivity(
      animal.id,
      activityId,
      done,
    );
    onMutated();
  }

  Future<void> _openDetail(BuildContext context) async {
    await Navigator.of(
      context,
    ).pushNamed(AppRoutes.livestockDetail, arguments: animal.id);
    onMutated();
  }

  @override
  Widget build(BuildContext context) {
    final summaries = repo.getSummariesForAnimal(animal.id)
      ..sort((a, b) => b.dateKey.compareTo(a.dateKey));
    final todayStr = LivestockDailySummary.dateKeyFor(DateTime.now());
    final todaySummary = summaries.where((s) => s.dateKey == todayStr).firstOrNull;
    final last7 = summaries
        .where((s) => s.dateKey.compareTo(_sevenDaysAgoKey()) >= 0)
        .toList();
    final deathsThisWeek = last7.fold<int>(0, (sum, s) => sum + s.deathsToday);
    final eggsThisWeek = last7.fold<int>(0, (sum, s) => sum + s.eggsToday);
    final milkThisWeek = last7.fold<double>(
      0,
      (sum, s) => sum + s.milkLitersToday,
    );
    final avgLive = last7.isEmpty
        ? animal.liveCount.toDouble()
        : last7.map((s) => s.liveCount).reduce((a, b) => a + b) / last7.length;
    final mortalityRatePct = avgLive <= 0
        ? 0.0
        : (deathsThisWeek / (avgLive * last7.length)) * 100;

    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final todayActivities = animal.activities
        .where(
          (a) =>
              !a.scheduledDate.isAfter(
                todayDate.add(const Duration(hours: 23, minutes: 59)),
              ) &&
              !a.scheduledDate.isBefore(todayDate),
        )
        .toList();
    final completedToday = todayActivities.where((a) => a.isCompleted).length;
    final totalCompleted = animal.completedActivityCount;
    final totalActivities = animal.activities.length;
    final completionRate = totalActivities == 0
        ? 0.0
        : totalCompleted / totalActivities;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/app_logo.png',
              width: 26,
              height: 26,
              errorBuilder: (_, _, _) => const Icon(Icons.bolt, size: 22),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                context.tr(AppStrings.liveTrack, AppStrings.liveTrackBn),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          const HeaderActionBar(),
          IconButton(
            tooltip: context.tr('Open full details', 'বিস্তারিত দেখুন'),
            icon: const Icon(Icons.open_in_new),
            onPressed: () => _openDetail(context),
          ),
        ],
      ),
      body: AgriAtmosphericBackground(
        child: AuthGate(
          featureName: context.tr('the livestock tracker', 'প্রাণী ট্র্যাকার'),
          child: RefreshIndicator(
            onRefresh: () async {
              await context.read<LivestockProvider>().refreshFromCloud();
              onMutated();
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _Header(animal: animal),
                const SizedBox(height: 16),
                _LiveStatsGrid(animal: animal, todaySummary: todaySummary),
                const SizedBox(height: 16),
                _AiSuggestionCard(animal: animal, todaySummary: todaySummary),
                const SizedBox(height: 16),
                _TodayLivestockActivityCard(
                  animal: animal,
                  todayActivities: todayActivities,
                  completedToday: completedToday,
                  onToggle: (id, done) => _toggleActivity(context, id, done),
                ),
                const SizedBox(height: 16),
                _LivestockCompletionRateCard(
                  animal: animal,
                  rate: completionRate,
                  totalCompleted: totalCompleted,
                  totalActivities: totalActivities,
                ),
                const SizedBox(height: 16),
                _LivestockMilestonesRoadmapCard(
                  animal: animal,
                  onToggle: (id, done) => _toggleActivity(context, id, done),
                ),
                const SizedBox(height: 16),
                if (animal.producesEggs || animal.producesMilk) ...[
                  _ProductionCard(
                    animal: animal,
                    todaySummary: todaySummary,
                    eggsThisWeek: eggsThisWeek,
                    milkThisWeek: milkThisWeek,
                  ),
                  const SizedBox(height: 16),
                ],
                _MortalityCard(
                  animal: animal,
                  todaySummary: todaySummary,
                  deathsThisWeek: deathsThisWeek,
                  mortalityRatePct: mortalityRatePct,
                  summaryCount: last7.length,
                ),
                const SizedBox(height: 60), // Room for FAB
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.danger,
        foregroundColor: Colors.white,
        onPressed: () => _recordDeaths(context),
        icon: const Icon(Icons.dangerous_outlined),
        label: Text(context.tr(AppStrings.recordDeaths, AppStrings.recordDeathsBn)),
      ),
    );
  }

  String _sevenDaysAgoKey() {
    final d = DateTime.now().subtract(const Duration(days: 6));
    return LivestockDailySummary.dateKeyFor(d);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.animal});
  final Animal animal;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.primaryGreen,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 26,
              backgroundColor: Colors.white24,
              child: Icon(Icons.pets, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    animal.species,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${animal.purpose} · ${context.isBn ? "${animal.daysSinceStart}তম দিন" : "Day ${animal.daysSinceStart}"}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            _PulseDot(),
          ],
        ),
      ),
    );
  }
}

/// Tiny pulsing dot to visually signal "live". Uses a stateful
/// animation so the dot throbs every second.
class _PulseDot extends StatefulWidget {
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Container(
          width: 12 + (_ctrl.value * 6),
          height: 12 + (_ctrl.value * 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.4 + _ctrl.value * 0.6),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

class _LiveStatsGrid extends StatelessWidget {
  const _LiveStatsGrid({required this.animal, required this.todaySummary});
  final Animal animal;
  final LivestockDailySummary? todaySummary;

  @override
  Widget build(BuildContext context) {
    final deathsToday = todaySummary?.deathsToday ?? 0;
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.favorite,
            color: AppTheme.success,
            label: context.tr(AppStrings.liveAnimals, AppStrings.liveAnimalsBn),
            value: '${animal.liveCount}',
            sub: context.tr('of ${animal.totalCount}', 'মোট ${animal.totalCount}টির মধ্যে'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            icon: Icons.dangerous_outlined,
            color: AppTheme.danger,
            label: context.tr('Died today', 'আজকের মৃত্যু'),
            value: '$deathsToday',
            sub: context.tr('total ${animal.deadCount}', 'মোট ${animal.deadCount}টি'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            icon: Icons.pets,
            color: AppTheme.primaryGreen,
            label: context.tr('Total', 'সর্বমোট'),
            value: '${animal.totalCount}',
            sub: '${context.tr("start", "শুরু")} ${Formatters.formatDate(animal.startDate, isBn: context.isBn)}',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.sub,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 10,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductionCard extends StatelessWidget {
  const _ProductionCard({
    required this.animal,
    required this.todaySummary,
    required this.eggsThisWeek,
    required this.milkThisWeek,
  });

  final Animal animal;
  final LivestockDailySummary? todaySummary;
  final int eggsThisWeek;
  final double milkThisWeek;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  animal.producesEggs
                      ? Icons.egg_outlined
                      : Icons.local_drink_outlined,
                  color: AppTheme.accentAmber,
                ),
                const SizedBox(width: 8),
                Text(
                  animal.producesEggs
                      ? context.tr("Today's egg production", "আজকের ডিম উৎপাদন")
                      : context.tr("Today's milk production", "আজকের দুধ উৎপাদন"),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (animal.producesEggs)
              _ProductionRow(
                color: AppTheme.accentAmber,
                icon: Icons.egg_outlined,
                today: '${todaySummary?.eggsToday ?? 0}',
                weekTotal: '$eggsThisWeek',
                weekAvg: last7Avg(eggsThisWeek),
              ),
            if (animal.producesMilk)
              _ProductionRow(
                color: AppTheme.skyBlue,
                icon: Icons.local_drink_outlined,
                today:
                    '${(todaySummary?.milkLitersToday ?? 0).toStringAsFixed(1)} ${context.tr("L", "লিটার")}',
                weekTotal: '${milkThisWeek.toStringAsFixed(1)} ${context.tr("L", "লিটার")}',
                weekAvg: '${last7Avg(milkThisWeek)} ${context.tr("L", "লিটার")}',
              ),
          ],
        ),
      ),
    );
  }

  String last7Avg(num total) =>
      (total / 7).toStringAsFixed(animal.producesMilk ? 1 : 0);
}

class _ProductionRow extends StatelessWidget {
  const _ProductionRow({
    required this.color,
    required this.icon,
    required this.today,
    required this.weekTotal,
    required this.weekAvg,
  });

  final Color color;
  final IconData icon;
  final String today;
  final String weekTotal;
  final String weekAvg;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('Today: $today', 'আজ: $today'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  context.tr(
                    '7-day total: $weekTotal  ·  avg/day: $weekAvg',
                    '৭ দিনের মোট: $weekTotal  ·  দৈনিক গড়: $weekAvg',
                  ),
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
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

class _MortalityCard extends StatelessWidget {
  const _MortalityCard({
    required this.animal,
    required this.todaySummary,
    required this.deathsThisWeek,
    required this.mortalityRatePct,
    required this.summaryCount,
  });

  final Animal animal;
  final LivestockDailySummary? todaySummary;
  final int deathsThisWeek;
  final double mortalityRatePct;
  final int summaryCount;

  @override
  Widget build(BuildContext context) {
    final rate = mortalityRatePct;
    final Color rateColor;
    final String rateLabel;
    if (rate < 1.0) {
      rateColor = AppTheme.success;
      rateLabel = context.tr('Stable', 'স্বাভাবিক');
    } else if (rate < 3.0) {
      rateColor = AppTheme.accentAmber;
      rateLabel = context.tr('Watch', 'নজর রাখুন');
    } else {
      rateColor = AppTheme.danger;
      rateLabel = context.tr('Critical', 'জরুরি');
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.show_chart, color: AppTheme.primaryGreen),
                const SizedBox(width: 8),
                Text(
                  context.tr('Mortality (7 days)', 'মৃত্যুর হার (৭ দিন)'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: rateColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, color: rateColor, size: 8),
                      const SizedBox(width: 6),
                      Text(
                        rateLabel,
                        style: TextStyle(
                          color: rateColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${rate.toStringAsFixed(2)}%',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: rateColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    context.tr(
                      'daily avg · $deathsThisWeek deaths',
                      'দৈনিক গড় · $deathsThisWeekটি মৃত্যু',
                    ),
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (rate / 10).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: rateColor.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation(rateColor),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              summaryCount == 0
                  ? context.tr(
                      'No summaries in the last 7 days — record today\'s data to start tracking mortality trends.',
                      'গত ৭ দিনে কোনো রেকর্ড নেই — প্রবণতা দেখতে আজকের তথ্য যোগ করুন।',
                    )
                  : context.tr(
                      'Calculated across $summaryCount day(s) of recorded data.',
                      '$summaryCount দিনের তথ্যের ভিত্তিতে হিসাব করা হয়েছে।',
                    ),
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}



IconData _livestockCatIcon(String cat) {
  switch (cat) {
    case AppConstants.lcatFeeding:
      return Icons.restaurant;
    case AppConstants.lcatWater:
      return Icons.water_drop;
    case AppConstants.lcatVaccination:
      return Icons.medical_services_outlined;
    case AppConstants.lcatCleaning:
      return Icons.cleaning_services_outlined;
    case AppConstants.lcatEggCollect:
      return Icons.egg_outlined;
    case AppConstants.lcatMilk:
      return Icons.local_drink_outlined;
    case AppConstants.lcatWeighing:
      return Icons.scale_outlined;
    default:
      return Icons.health_and_safety_outlined;
  }
}

Color _livestockCatColor(String cat) {
  switch (cat) {
    case AppConstants.lcatFeeding:
      return AppTheme.accentAmber;
    case AppConstants.lcatWater:
      return AppTheme.skyBlue;
    case AppConstants.lcatVaccination:
      return AppTheme.danger;
    case AppConstants.lcatCleaning:
      return AppTheme.earthBrown;
    case AppConstants.lcatEggCollect:
      return Colors.orange;
    case AppConstants.lcatMilk:
      return Colors.blue;
    case AppConstants.lcatWeighing:
      return Colors.purple;
    default:
      return AppTheme.primaryGreen;
  }
}

class _TodayLivestockActivityCard extends StatelessWidget {
  const _TodayLivestockActivityCard({
    required this.animal,
    required this.todayActivities,
    required this.completedToday,
    required this.onToggle,
  });

  final Animal animal;
  final List<LivestockActivity> todayActivities;
  final int completedToday;
  final void Function(String activityId, bool done) onToggle;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final upcomingPending = animal.activities.where((a) => !a.isCompleted).toList()
      ..sort((a, b) => a.dayFromStart.compareTo(b.dayFromStart));
    final nextMilestone = upcomingPending.firstOrNull;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppTheme.primaryGreen.withValues(alpha: 0.25),
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.alarm_on, color: AppTheme.primaryGreen, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.tr("Today's Care & Next Task", "আজকের যত্ন ও পরবর্তী কাজ"),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                if (todayActivities.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$completedToday/${todayActivities.length}',
                      style: const TextStyle(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            if (todayActivities.isNotEmpty) ...[
              for (final a in todayActivities)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: a.isCompleted
                        ? AppTheme.success.withValues(alpha: 0.08)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: a.isCompleted
                          ? AppTheme.success.withValues(alpha: 0.3)
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _livestockCatIcon(a.category),
                        color: _livestockCatColor(a.category),
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.getTitle(context.isBn),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                decoration: a.isCompleted ? TextDecoration.lineThrough : null,
                                color: a.isCompleted ? AppTheme.textSecondary : AppTheme.textPrimary,
                              ),
                            ),
                            if (a.getDescription(context.isBn).isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  a.getDescription(context.isBn),
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Checkbox(
                        value: a.isCompleted,
                        activeColor: AppTheme.primaryGreen,
                        onChanged: (val) => onToggle(a.id, val ?? false),
                      ),
                    ],
                  ),
                ),
            ] else if (nextMilestone != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _livestockCatColor(nextMilestone.category),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            context.isBn
                                ? "${nextMilestone.dayFromStart}তম দিন"
                                : "Day ${nextMilestone.dayFromStart}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            context.isBn
                                ? "পরবর্তী নির্ধারিত কাজ"
                                : "Next Upcoming Milestone Task",
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        _buildLivestockDaysBadge(context, nextMilestone.scheduledDate, today),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _livestockCatIcon(nextMilestone.category),
                          color: _livestockCatColor(nextMilestone.category),
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nextMilestone.getTitle(context.isBn),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              if (nextMilestone.getDescription(context.isBn).isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    nextMilestone.getDescription(context.isBn),
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lock_clock, size: 16, color: AppTheme.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.tr(
                                'This care task will unlock on Day ${nextMilestone.dayFromStart}.',
                                '${nextMilestone.dayFromStart}তম দিন শুরু হলে এই কাজটি সক্রিয় হবে।',
                              ),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified, color: AppTheme.success),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.tr(
                          'All health and care milestones are completed!',
                          'প্রাণীর সকল স্বাস্থ্য ও যত্ন সংক্রান্ত কাজ সফলভাবে সম্পন্ন হয়েছে!',
                        ),
                        style: const TextStyle(
                          color: AppTheme.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLivestockDaysBadge(BuildContext context, DateTime scheduled, DateTime today) {
    final diff = DateTime(scheduled.year, scheduled.month, scheduled.day)
        .difference(today)
        .inDays;
    if (diff == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          context.tr('Today', 'আজ'),
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      );
    } else if (diff > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppTheme.skyBlue.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          context.tr('in $diff days', '$diff দিন পর'),
          style: const TextStyle(color: AppTheme.skyBlue, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppTheme.danger.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          context.tr('${-diff}d ago', '${-diff} দিন আগের'),
          style: const TextStyle(color: AppTheme.danger, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      );
    }
  }
}

class _LivestockCompletionRateCard extends StatelessWidget {
  const _LivestockCompletionRateCard({
    required this.animal,
    required this.rate,
    required this.totalCompleted,
    required this.totalActivities,
  });

  final Animal animal;
  final double rate;
  final int totalCompleted;
  final int totalActivities;

  @override
  Widget build(BuildContext context) {
    final pct = (rate * 100).toStringAsFixed(0);
    final Color rateColor;
    final String rateLabel;
    if (rate >= 0.8) {
      rateColor = AppTheme.success;
      rateLabel = context.tr('On track', 'সঠিক গতিতে');
    } else if (rate >= 0.5) {
      rateColor = AppTheme.accentAmber;
      rateLabel = context.tr('Watch', 'নজর রাখুন');
    } else {
      rateColor = AppTheme.danger;
      rateLabel = context.tr('Behind', 'বিলম্বিত');
    }
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.show_chart, color: AppTheme.primaryGreen),
                const SizedBox(width: 8),
                Text(
                  context.tr('Health & Care Progress', 'স্বাস্থ্য ও যত্নের অগ্রগতি'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: rateColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, color: rateColor, size: 8),
                      const SizedBox(width: 6),
                      Text(
                        rateLabel,
                        style: TextStyle(
                          color: rateColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$pct%',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: rateColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    context.tr(
                      'done · $totalCompleted of $totalActivities',
                      'সম্পন্ন · $totalActivitiesটির মধ্যে $totalCompletedটি',
                    ),
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: rate,
                minHeight: 8,
                backgroundColor: rateColor.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation(rateColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LivestockMilestonesRoadmapCard extends StatefulWidget {
  const _LivestockMilestonesRoadmapCard({
    required this.animal,
    required this.onToggle,
  });

  final Animal animal;
  final void Function(String activityId, bool done) onToggle;

  @override
  State<_LivestockMilestonesRoadmapCard> createState() => _LivestockMilestonesRoadmapCardState();
}

class _LivestockMilestonesRoadmapCardState extends State<_LivestockMilestonesRoadmapCard> {
  int _filterIndex = 0; // 0: All, 1: Pending, 2: Done

  @override
  Widget build(BuildContext context) {
    final acts = [...widget.animal.activities]
      ..sort((a, b) => a.dayFromStart.compareTo(b.dayFromStart));

    final filtered = acts.where((a) {
      if (_filterIndex == 1) return !a.isCompleted;
      if (_filterIndex == 2) return a.isCompleted;
      return true;
    }).toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.event_note, color: AppTheme.primaryGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr(
                      'Livestock Care & Vaccine Roadmap',
                      'সম্পূর্ণ স্বাস্থ্য ও টিকাদানের সময়সূচি',
                    ),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Filter tabs
            Row(
              children: [
                _filterChip(0, context.tr('All (${acts.length})', 'সকল (${acts.length})')),
                const SizedBox(width: 8),
                _filterChip(1, context.tr('Pending (${widget.animal.upcomingActivityCount})', 'বাকি (${widget.animal.upcomingActivityCount})')),
                const SizedBox(width: 8),
                _filterChip(2, context.tr('Done (${widget.animal.completedActivityCount})', 'সম্পন্ন (${widget.animal.completedActivityCount})')),
              ],
            ),
            const SizedBox(height: 14),
            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    context.tr('No tasks in this filter.', 'এই ফিল্টারে কোনো কাজ নেই।'),
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const Divider(height: 14),
                itemBuilder: (context, index) {
                  final a = filtered[index];
                  final catColor = _livestockCatColor(a.category);
                  final hasStarted = a.dayFromStart <= widget.animal.daysSinceStart;
                  final canToggle = hasStarted || a.isCompleted;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Milestone Day pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                        decoration: BoxDecoration(
                          color: catColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: catColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          context.isBn ? "${a.dayFromStart}তম দিন" : "Day ${a.dayFromStart}",
                          style: TextStyle(
                            color: catColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: canToggle
                              ? () => widget.onToggle(a.id, !a.isCompleted)
                              : () {
                                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        context.isBn
                                            ? '${a.dayFromStart}তম দিন শুরু হওয়ার আগে এই কাজটি সম্পন্ন করা যাবে না!'
                                            : 'This task starts on Day ${a.dayFromStart}. You cannot complete it before it starts!',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: AppTheme.accentAmber,
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  a.getTitle(context.isBn),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13.5,
                                    decoration: a.isCompleted ? TextDecoration.lineThrough : null,
                                    color: !hasStarted && !a.isCompleted
                                        ? AppTheme.textSecondary
                                        : AppTheme.textPrimary,
                                  ),
                                ),
                                if (a.getDescription(context.isBn).isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      a.getDescription(context.isBn),
                                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (canToggle)
                        Checkbox(
                          value: a.isCompleted,
                          activeColor: AppTheme.primaryGreen,
                          onChanged: (val) => widget.onToggle(a.id, val ?? false),
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.lock_clock, size: 20, color: AppTheme.textSecondary),
                          tooltip: context.isBn ? 'এখনও শুরু হয়নি' : 'Not started yet',
                          onPressed: () {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  context.isBn
                                      ? '${a.dayFromStart}তম দিন শুরু হওয়ার আগে এই কাজটি সম্পন্ন করা যাবে না!'
                                      : 'This task starts on Day ${a.dayFromStart}. You cannot complete it before it starts!',
                                ),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: AppTheme.accentAmber,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          },
                        ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(int index, String label) {
    final selected = _filterIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _filterIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryGreen : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _AiSuggestionCard extends StatefulWidget {
  const _AiSuggestionCard({
    required this.animal,
    required this.todaySummary,
  });
  final Animal animal;
  final LivestockDailySummary? todaySummary;

  @override
  State<_AiSuggestionCard> createState() => _AiSuggestionCardState();
}

class _AiSuggestionCardState extends State<_AiSuggestionCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final prov = context.read<LivestockDailySuggestionsProvider>();
      prov.primeFromCache(widget.animal.id);
      if (!prov.hasFreshTodayRecord(widget.animal.id)) {
        prov.ensureToday(widget.animal, widget.todaySummary);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LivestockDailySuggestionsProvider>(
      builder: (context, prov, _) {
        final suggestion = prov.suggestionFor(widget.animal.id);
        final loading = prov.isLoading(widget.animal.id);
        final error = prov.errorFor(widget.animal.id);

        return Card(
          color: AppTheme.primaryGreenLight.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: AppTheme.primaryGreen,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.tr(AppStrings.aiAdviceTitle, AppStrings.aiAdviceTitleBn),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (suggestion != null)
                      _LiveTrackSourceChip(source: suggestion.source),
                    IconButton(
                      tooltip: context.tr(AppStrings.refresh, AppStrings.refreshBn),
                      icon: loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      onPressed: loading
                          ? null
                          : () => prov.refreshFor(widget.animal, widget.todaySummary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (suggestion == null && loading)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(context.tr(AppStrings.aiAdviceThinking, AppStrings.aiAdviceThinkingBn)),
                  )
                else if (suggestion == null)
                  Text(
                    error ?? context.tr(AppStrings.aiAdviceEmpty, AppStrings.aiAdviceEmptyBn),
                    style: const TextStyle(color: AppTheme.textSecondary),
                  )
                else
                  _LiveTrackSuggestionBody(
                    suggestion: suggestion,
                    animal: widget.animal,
                    prov: prov,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LiveTrackSuggestionBody extends StatelessWidget {
  const _LiveTrackSuggestionBody({
    required this.suggestion,
    required this.animal,
    required this.prov,
  });
  final LivestockDailySuggestion suggestion;
  final Animal animal;
  final LivestockDailySuggestionsProvider prov;

  @override
  Widget build(BuildContext context) {
    final stale = prov.isStaleFor(animal.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${context.isBn ? "${suggestion.dayFromStart}তম দিন" : "Day ${suggestion.dayFromStart}"} · ${suggestion.dateKey}',
                style: const TextStyle(
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (stale)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accentAmber.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  context.tr(AppStrings.aiAdviceStale, AppStrings.aiAdviceStaleBn),
                  style: const TextStyle(
                    color: AppTheme.accentAmber,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(suggestion.guidance),
        if (suggestion.doItems.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            context.tr(AppStrings.aiAdviceDo, AppStrings.aiAdviceDoBn),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppTheme.primaryGreen,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          ...suggestion.doItems.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: AppTheme.primaryGreen,
                  ),
                  const SizedBox(width: 6),
                  Expanded(child: Text(item, style: const TextStyle(fontSize: 13))),
                ],
              ),
            ),
          ),
        ],
        if (suggestion.dontItems.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            context.tr(AppStrings.aiAdviceDont, AppStrings.aiAdviceDontBn),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppTheme.danger,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          ...suggestion.dontItems.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.cancel_outlined,
                    size: 16,
                    color: AppTheme.danger,
                  ),
                  const SizedBox(width: 6),
                  Expanded(child: Text(item, style: const TextStyle(fontSize: 13))),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _LiveTrackSourceChip extends StatelessWidget {
  const _LiveTrackSourceChip({required this.source});
  final String source;

  @override
  Widget build(BuildContext context) {
    final isGemini = source.startsWith('gemini');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (isGemini ? AppTheme.primaryGreen : AppTheme.accentAmber)
            .withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isGemini ? 'Gemini 3.5' : 'Offline',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isGemini ? AppTheme.primaryGreen : AppTheme.accentAmber,
        ),
      ),
    );
  }
}

