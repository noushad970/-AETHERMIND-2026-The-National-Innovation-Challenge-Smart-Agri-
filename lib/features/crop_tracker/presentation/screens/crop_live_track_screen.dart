import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/widgets/agri_atmospheric_background.dart';
import '../../../../core/widgets/auth_gate.dart';
import '../../../../core/widgets/header_action_bar.dart';
import '../../../../core/widgets/live_pulse_badge.dart';
import '../../../../data/models/crop.dart';
import '../../../../data/models/crop_activity.dart';
import '../../../../data/models/daily_suggestion.dart';
import '../providers/crops_provider.dart';
import '../providers/daily_suggestions_provider.dart';

/// "Live Track" view for a single crop. Mirrors
/// [LivestockLiveTrackScreen] but tailored to crop cultivation:
///
///   • days since planting, days remaining until harvest
///   • current growth stage and progress bar
///   • today's scheduled activity (if any) + a quick "mark done"
///     action so logging takes one tap
///   • overall activity completion rate so you can see at a glance
///     how on-track the crop is
///   • a 7-day recent activity history
///
/// Everything is read from Firestore via [CropsProvider] so the screen
/// stays in sync across devices. Writes update the same Firestore
/// documents and the provider notifies on every snapshot.
class CropLiveTrackScreen extends StatefulWidget {
  const CropLiveTrackScreen({super.key, required this.cropId});
  final String cropId;

  @override
  State<CropLiveTrackScreen> createState() => _CropLiveTrackScreenState();
}

class _CropLiveTrackScreenState extends State<CropLiveTrackScreen> {
  // Bumped after any write so the page re-derives its stats from Firestore.
  int _version = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CropsProvider>().refreshFromCloud();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CropsProvider>(
      builder: (context, prov, _) {
        final _ = _version;
        final crop = prov.byId(widget.cropId);
        if (crop == null) {
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
                            Icons.eco_outlined,
                            size: 64,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            context.tr(
                              'Crop data is loading or record not found',
                              'ফসলের তথ্য লোড হচ্ছে বা খুঁজে পাওয়া যায়নি',
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
          crop: crop,
          onMutated: () => setState(() => _version++),
        );
      },
    );
  }
}

class _Scaffold extends StatelessWidget {
  const _Scaffold({required this.crop, required this.onMutated});

  final Crop crop;
  final VoidCallback onMutated;

  Future<void> _markActivity(BuildContext context, String activityId) async {
    await context.read<CropsProvider>().toggleActivity(
      crop.id,
      activityId,
      true,
    );
    onMutated();
  }

  Future<void> _toggleActivity(
    BuildContext context,
    String activityId,
    bool done,
  ) async {
    await context.read<CropsProvider>().toggleActivity(
      crop.id,
      activityId,
      done,
    );
    onMutated();
  }

  Future<void> _openDetail(BuildContext context) async {
    await Navigator.of(
      context,
    ).pushNamed(AppRoutes.cropDetail, arguments: crop.id);
    onMutated();
  }

  /// Picker for the next upcoming activity within the next [days]
  /// days. Used by the FAB.
  Future<void> _openUpcomingPicker(BuildContext context) async {
    final now = DateTime.now();
    final upcoming =
        crop.activities
            .where(
              (a) =>
                  !a.isCompleted &&
                  a.scheduledDate.difference(now).inDays <= 7 &&
                  a.scheduledDate.difference(now).inDays >= -1,
            )
            .toList()
          ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
    if (upcoming.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              'No upcoming activity in the next 7 days',
              'পরবর্তী ৭ দিনে কোনো নির্ধারিত কাজ নেই',
            ),
          ),
        ),
      );
      return;
    }
    final pickedId = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: Text(
          context.tr('Mark activity complete', 'কাজ সম্পন্ন চিহ্নিত করুন'),
        ),
        children: [
          for (final a in upcoming)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, a.id),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.getTitle(context.isBn)),
                        Text(
                          Formatters.date.format(a.scheduledDate),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
    if (pickedId == null) return;
    if (!context.mounted) return;
    final cropsProv = context.read<CropsProvider>();
    await cropsProv.toggleActivity(crop.id, pickedId, true);
    if (!context.mounted) return;
    onMutated();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayActivities = crop.activities
        .where(
          (a) =>
              !a.scheduledDate.isAfter(
                today.add(const Duration(hours: 23, minutes: 59)),
              ) &&
              !a.scheduledDate.isBefore(today),
        )
        .toList();
    final completedToday = todayActivities.where((a) => a.isCompleted).length;
    final totalCompleted = crop.completedActivityCount;
    final totalUpcoming = crop.upcomingActivityCount;
    final totalActivities = crop.activities.length;
    final completionRate = totalActivities == 0
        ? 0.0
        : totalCompleted / totalActivities;
    final hasTrees = crop.numberOfTrees != null && crop.numberOfTrees! > 0;

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
          featureName: context.tr('the crop tracker', 'ফসল ট্র্যাকার'),
          child: RefreshIndicator(
            onRefresh: () async {
              await context.read<CropsProvider>().refreshFromCloud();
              onMutated();
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _Header(crop: crop),
                const SizedBox(height: 16),
                _LiveStatsGrid(crop: crop),
                const SizedBox(height: 16),
                _GrowthStageCard(crop: crop),
                const SizedBox(height: 16),
                _AiSuggestionCard(crop: crop),
                const SizedBox(height: 16),
                _TodayActivityCard(
                  crop: crop,
                  todayActivities: todayActivities,
                  completedToday: completedToday,
                  onMark: (id) => _markActivity(context, id),
                ),
                const SizedBox(height: 16),
                _CompletionRateCard(
                  crop: crop,
                  rate: completionRate,
                  totalCompleted: totalCompleted,
                  totalUpcoming: totalUpcoming,
                  totalActivities: totalActivities,
                ),
                const SizedBox(height: 16),
                _CropMilestonesRoadmapCard(
                  crop: crop,
                  onToggle: (id, done) => _toggleActivity(context, id, done),
                ),
                const SizedBox(height: 16),
                if (hasTrees) ...[
                  _OrchardCard(crop: crop),
                  const SizedBox(height: 16),
                ],
                const SizedBox(height: 60), // Room for FAB
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        onPressed: () => _openUpcomingPicker(context),
        icon: const Icon(Icons.check_circle_outline),
        label: Text(context.tr('Mark activity', 'কাজ সম্পন্ন করুন')),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.crop});
  final Crop crop;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F5C4A),
            Color(0xFF1B7A5C),
            Color(0xFF00695C),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F5C4A).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.eco, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  crop.cropType,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${crop.variety}  ·  ${context.isBn ? "${crop.daysSincePlanting}তম দিন" : "Day ${crop.daysSincePlanting}"}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const LivePulseBadge(
            color: AppTheme.sunYellow,
            size: 10,
          ),
        ],
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
  const _LiveStatsGrid({required this.crop});
  final Crop crop;

  @override
  Widget build(BuildContext context) {
    final daysLeft = crop.daysRemainingUntilHarvest;
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.calendar_today,
            color: AppTheme.success,
            label: context.tr('Planted', 'রোপণকাল'),
            value: context.isBn ? "${crop.daysSincePlanting}তম দিন" : "Day ${crop.daysSincePlanting}",
            sub: Formatters.date.format(crop.plantingDate),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            icon: Icons.event,
            color: AppTheme.primaryGreen,
            label: context.tr('Harvest in', 'কর্তন বাকি'),
            value: daysLeft == 0
                ? context.tr('Now', 'এখনই')
                : (context.isBn ? '$daysLeft দিন' : '$daysLeft d'),
            sub: Formatters.date.format(crop.estimatedHarvestDate),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            icon: Icons.landscape,
            color: AppTheme.earthBrown,
            label: context.tr('Land area', 'জমির পরিমাণ'),
            value: crop.landAreaDecimal.toStringAsFixed(2),
            sub: context.tr('decimal', 'শতাংশ'),
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

class _GrowthStageCard extends StatelessWidget {
  const _GrowthStageCard({required this.crop});
  final Crop crop;

  @override
  Widget build(BuildContext context) {
    final pct = (crop.progress * 100).toStringAsFixed(0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.spa, color: AppTheme.primaryGreen),
                const SizedBox(width: 8),
                Text(
                  crop.getCurrentGrowthStage(context.isBn),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  '$pct%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: crop.progress,
                minHeight: 8,
                backgroundColor: AppTheme.primaryGreenLight.withValues(
                  alpha: 0.3,
                ),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryGreen,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.tr(
                'Total ${crop.totalGrowthDays}-day cycle',
                'সর্বমোট ${crop.totalGrowthDays} দিনের চক্র',
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

IconData _cropCatIcon(String cat) {
  switch (cat) {
    case 'irrigation':
      return Icons.water_drop_outlined;
    case 'fertilizer':
      return Icons.science_outlined;
    case 'pest':
      return Icons.bug_report_outlined;
    case 'weed':
      return Icons.grass_outlined;
    case 'harvest':
      return Icons.agriculture_outlined;
    default:
      return Icons.task_alt;
  }
}

Color _cropCatColor(String cat) {
  switch (cat) {
    case 'irrigation':
      return AppTheme.skyBlue;
    case 'fertilizer':
      return AppTheme.accentAmber;
    case 'pest':
      return AppTheme.danger;
    case 'weed':
      return AppTheme.earthBrown;
    case 'harvest':
      return AppTheme.success;
    default:
      return AppTheme.primaryGreen;
  }
}

class _TodayActivityCard extends StatelessWidget {
  const _TodayActivityCard({
    required this.crop,
    required this.todayActivities,
    required this.completedToday,
    required this.onMark,
  });

  final Crop crop;
  final List<CropActivity> todayActivities;
  final int completedToday;
  final void Function(String activityId) onMark;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final upcomingPending = crop.activities.where((a) => !a.isCompleted).toList()
      ..sort((a, b) => a.dayFromPlanting.compareTo(b.dayFromPlanting));
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
                    context.tr("Today's Tasks & Next Milestone", "আজকের কাজ ও পরবর্তী ধাপ"),
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
                        _cropCatIcon(a.category),
                        color: _cropCatColor(a.category),
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
                      if (!a.isCompleted)
                        ElevatedButton.icon(
                          onPressed: () => onMark(a.id),
                          icon: const Icon(Icons.check, size: 16),
                          label: Text(context.tr('Done', 'সম্পন্ন')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: Size.zero,
                          ),
                        )
                      else
                        const Icon(Icons.check_circle, color: AppTheme.success, size: 22),
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
                            color: _cropCatColor(nextMilestone.category),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            context.isBn
                                ? "${nextMilestone.dayFromPlanting}তম দিন"
                                : "Day ${nextMilestone.dayFromPlanting}",
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
                                ? "পরবর্তী ধাপের নির্ধারিত কাজ"
                                : "Next Upcoming Milestone Task",
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        _buildDaysBadge(context, nextMilestone.scheduledDate, today),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _cropCatIcon(nextMilestone.category),
                          color: _cropCatColor(nextMilestone.category),
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
                                'This task will unlock on Day ${nextMilestone.dayFromPlanting}.',
                                '${nextMilestone.dayFromPlanting}তম দিন শুরু হলে কাজটি সক্রিয় হবে।',
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
                          'All cultivation milestone activities are completed!',
                          'ফসলের সকল নির্ধারিত কাজ সফলভাবে সম্পন্ন হয়েছে!',
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

  Widget _buildDaysBadge(BuildContext context, DateTime scheduled, DateTime today) {
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

class _CropMilestonesRoadmapCard extends StatefulWidget {
  const _CropMilestonesRoadmapCard({
    required this.crop,
    required this.onToggle,
  });

  final Crop crop;
  final void Function(String activityId, bool done) onToggle;

  @override
  State<_CropMilestonesRoadmapCard> createState() => _CropMilestonesRoadmapCardState();
}

class _CropMilestonesRoadmapCardState extends State<_CropMilestonesRoadmapCard> {
  int _filterIndex = 0; // 0: All, 1: Pending, 2: Done

  @override
  Widget build(BuildContext context) {
    final acts = [...widget.crop.activities]
      ..sort((a, b) => a.dayFromPlanting.compareTo(b.dayFromPlanting));

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
                      'Crop Life-Cycle Task Roadmap',
                      'ফসলের পূর্ণাঙ্গ কাজের সময়সূচি',
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
                _filterChip(1, context.tr('Pending (${widget.crop.upcomingActivityCount})', 'বাকি (${widget.crop.upcomingActivityCount})')),
                const SizedBox(width: 8),
                _filterChip(2, context.tr('Done (${widget.crop.completedActivityCount})', 'সম্পন্ন (${widget.crop.completedActivityCount})')),
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
                  final catColor = _cropCatColor(a.category);
                  final hasStarted = a.dayFromPlanting <= widget.crop.daysSincePlanting;
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
                          context.isBn ? "${a.dayFromPlanting}তম দিন" : "Day ${a.dayFromPlanting}",
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
                                            ? '${a.dayFromPlanting}তম দিন শুরু হওয়ার আগে এই কাজটি সম্পন্ন করা যাবে না!'
                                            : 'This task starts on Day ${a.dayFromPlanting}. You cannot complete it before it starts!',
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
                                      ? '${a.dayFromPlanting}তম দিন শুরু হওয়ার আগে এই কাজটি সম্পন্ন করা যাবে না!'
                                      : 'This task starts on Day ${a.dayFromPlanting}. You cannot complete it before it starts!',
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

class _CompletionRateCard extends StatelessWidget {
  const _CompletionRateCard({
    required this.crop,
    required this.rate,
    required this.totalCompleted,
    required this.totalUpcoming,
    required this.totalActivities,
  });

  final Crop crop;
  final double rate;
  final int totalCompleted;
  final int totalUpcoming;
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
                  context.tr('Activity completion', 'কাজের সমাপ্তির হার'),
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
            const SizedBox(height: 8),
            Text(
              totalActivities == 0
                  ? context.tr(
                      'No activities scheduled for this crop yet.',
                      'এখনো কোনো কার্যক্রম নির্ধারিত হয়নি।',
                    )
                  : context.tr(
                      '$totalUpcoming upcoming task(s) remaining.',
                      '$totalUpcomingটি আসন্ন কাজ বাকি রয়েছে।',
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

class _OrchardCard extends StatelessWidget {
  const _OrchardCard({required this.crop});
  final Crop crop;

  @override
  Widget build(BuildContext context) {
    final total = (crop.numberOfTrees ?? 0) + crop.newlyPlantedTrees;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.park, color: AppTheme.primaryGreen),
                const SizedBox(width: 8),
                Text(
                  context.tr(AppStrings.orchard, AppStrings.orchardBn),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.favorite,
                    color: AppTheme.success,
                    label: context.tr(AppStrings.live, AppStrings.liveBn),
                    value: '${crop.liveTrees}',
                    sub: context.tr('of $total', 'মোট $totalটির'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(
                    icon: Icons.warning_amber,
                    color: AppTheme.danger,
                    label: context.tr(AppStrings.dead, AppStrings.deadBn),
                    value: '${crop.deadTrees}',
                    sub: context.tr('${crop.newlyPlantedTrees} new', '${crop.newlyPlantedTrees}টি নতুন'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(
                    icon: Icons.pets,
                    color: AppTheme.primaryGreen,
                    label: context.tr(AppStrings.total, AppStrings.totalBn),
                    value: '$total',
                    sub: context.tr('${crop.numberOfTrees ?? 0} planned', '${crop.numberOfTrees ?? 0}টি নির্ধারিত'),
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



class _AiSuggestionCard extends StatefulWidget {
  const _AiSuggestionCard({required this.crop});
  final Crop crop;

  @override
  State<_AiSuggestionCard> createState() => _AiSuggestionCardState();
}

class _AiSuggestionCardState extends State<_AiSuggestionCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final prov = context.read<DailySuggestionsProvider>();
      prov.primeFromCache(widget.crop.id);
      if (!prov.hasFreshTodayRecord(widget.crop.id)) {
        prov.ensureToday(widget.crop);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DailySuggestionsProvider>(
      builder: (context, prov, _) {
        final suggestion = prov.suggestionFor(widget.crop.id);
        final loading = prov.isLoading(widget.crop.id);
        final error = prov.errorFor(widget.crop.id);

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
                          : () => prov.refreshFor(widget.crop),
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
                    crop: widget.crop,
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
    required this.crop,
    required this.prov,
  });
  final DailySuggestion suggestion;
  final Crop crop;
  final DailySuggestionsProvider prov;

  @override
  Widget build(BuildContext context) {
    final stale = prov.isStaleFor(crop.id);
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
                '${context.isBn ? "${suggestion.dayFromPlanting}তম দিন" : "Day ${suggestion.dayFromPlanting}"} · ${suggestion.dateKey}',
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
          _LiveTrackBulletList(
            items: suggestion.doItems,
            color: AppTheme.primaryGreen,
          ),
        ],
        if (suggestion.dontItems.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            context.tr(AppStrings.aiAdviceDont, AppStrings.aiAdviceDontBn),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.redAccent,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          _LiveTrackBulletList(
            items: suggestion.dontItems,
            color: Colors.redAccent,
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
    final isOffline = source == 'fallback' || source == 'offline';
    final color = isOffline ? AppTheme.textSecondary : AppTheme.primaryGreen;
    final label = isOffline
        ? context.tr(AppStrings.aiAdviceSourceOffline, AppStrings.aiAdviceSourceOfflineBn)
        : context.tr(AppStrings.aiAdviceSourceGemini, AppStrings.aiAdviceSourceGeminiBn);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _LiveTrackBulletList extends StatelessWidget {
  const _LiveTrackBulletList({required this.items, required this.color});
  final List<String> items;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final t in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('•  ', style: TextStyle(color: color, fontSize: 14)),
                Expanded(child: Text(t)),
              ],
            ),
          ),
      ],
    );
  }
}
