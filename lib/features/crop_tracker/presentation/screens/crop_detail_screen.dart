import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/layout/adaptive_two_pane.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/header_action_bar.dart';
import '../../../../data/models/crop.dart';

import '../../../../data/models/crop_activity.dart';
import '../../../../data/models/daily_suggestion.dart';
import '../providers/crops_provider.dart';
import '../providers/daily_suggestions_provider.dart';

class CropDetailScreen extends StatelessWidget {
  const CropDetailScreen({super.key, required this.cropId});

  final String cropId;

  @override
  Widget build(BuildContext context) {
    return Consumer<CropsProvider>(
      builder: (context, prov, _) {
        final crop = prov.crops.where((c) => c.id == cropId).firstOrNull;
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
                    errorBuilder: (_, _, _) => const Icon(Icons.eco, size: 22),
                  ),
                  const SizedBox(width: 8),
                  Text(context.tr(AppStrings.cropDetail, AppStrings.cropDetailBn)),
                ],
              ),
              actions: const [
                HeaderActionBar(),
                SizedBox(width: 8),
              ],
            ),
            body: EmptyState(
              icon: Icons.error_outline,
              title: context.tr('Crop not found', 'ফসল খুঁজে পাওয়া যায়নি'),
              subtitle: context.tr('It may have been removed.', 'এটি হয়তো মুছে ফেলা হয়েছে।'),
            ),
          );
        }
        return _Body(crop: crop);
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.crop});
  final Crop crop;

  @override
  Widget build(BuildContext context) {
    final stage = crop.currentGrowthStage;
    final remaining = crop.daysRemainingUntilHarvest;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/app_logo.png',
              width: 26,
              height: 26,
              errorBuilder: (_, _, _) => const Icon(Icons.eco, size: 22),
            ),
            const SizedBox(width: 8),
            Text(crop.cropType),
          ],
        ),
        actions: [
          const HeaderActionBar(),
          IconButton(
            tooltip: context.tr(AppStrings.liveTrack, AppStrings.liveTrackBn),
            icon: const Icon(Icons.bolt, color: AppTheme.accentAmber),
            onPressed: () => Navigator.of(context).pushNamed(
              AppRoutes.cropLiveTrack,
              arguments: crop.id,
            ),
          ),
          IconButton(
            tooltip: context.tr(AppStrings.deleteCrop, AppStrings.deleteCropBn),
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text(AppStrings.deleteCrop),
                  content: Text('Delete ${crop.cropType}?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text(AppStrings.cancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(AppStrings.delete),
                    ),
                  ],
                ),
              );
              if (ok == true && context.mounted) {
                await context.read<CropsProvider>().delete(crop.id);
                if (context.mounted) {
                  context.read<DailySuggestionsProvider>().forget(crop.id);
                  Navigator.of(context).pop();
                }
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<CropsProvider>().refreshFromCloud(),
        child: AdaptiveTwoPane(
          primary: [
            _OverviewCard(crop: crop, stage: stage, remaining: remaining),
            const SizedBox(height: 16),
            _AiSuggestionCard(crop: crop),
            const SizedBox(height: 16),
            _TodaysTasksCard(crop: crop),
            if (crop.numberOfTrees != null && crop.numberOfTrees! > 0) ...[
              const SizedBox(height: 16),
              _OrchardCard(crop: crop),
            ],
            const SizedBox(height: 16),
          ],
          secondary: [
            Text(
              context.tr(AppStrings.activityTimeline, AppStrings.activityTimelineBn),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _TimelineList(crop: crop),
            if (crop.notes.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr(AppStrings.notes, AppStrings.notesBn),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(crop.notes),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.crop,
    required this.stage,
    required this.remaining,
  });
  final Crop crop;
  final String stage;
  final int remaining;

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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        crop.variety.isNotEmpty ? crop.variety : crop.cropType,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Formatters.formatDate(crop.plantingDate, isBn: context.isBn),
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    stage,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: crop.progress,
              minHeight: 8,
              backgroundColor: AppTheme.primaryGreenLight.withValues(
                alpha: 0.2,
              ),
              valueColor: const AlwaysStoppedAnimation(AppTheme.primaryGreen),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${crop.daysSincePlanting} ${context.tr(AppStrings.daysOld, AppStrings.daysOldBn)}'),
                Text(
                  remaining > 0
                      ? '$remaining ${context.tr(AppStrings.daysToHarvest, AppStrings.daysToHarvestBn)}'
                      : context.tr(AppStrings.readyToHarvest, AppStrings.readyToHarvestBn),
                  style: TextStyle(
                    color: remaining > 0
                        ? AppTheme.textSecondary
                        : AppTheme.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _Stat(
                    icon: Icons.straighten,
                    label: '${crop.landAreaDecimal} ${context.tr(AppStrings.decimal, AppStrings.decimalBn)}',
                  ),
                ),
                if (crop.numberOfTrees != null && crop.numberOfTrees! > 0)
                  Expanded(
                    child: _Stat(
                      icon: Icons.park_outlined,
                      label: '${crop.liveTrees} ${context.tr(AppStrings.trees, AppStrings.treesBn)}',
                    ),
                  ),
                Expanded(
                  child: _Stat(
                    icon: Icons.task_alt,
                    label:
                        '${crop.completedActivityCount}/${crop.activities.length}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pushNamed(
                  AppRoutes.cropLiveTrack,
                  arguments: crop.id,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.bolt, size: 18, color: AppTheme.accentAmber),
                label: Text(
                  context.tr('Open Live Tracking Dashboard', 'লাইভ ট্র্যাকিং ড্যাশবোর্ড খুলুন'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryGreen),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _OrchardCard extends StatefulWidget {
  const _OrchardCard({required this.crop});
  final Crop crop;

  @override
  State<_OrchardCard> createState() => _OrchardCardState();
}

class _OrchardCardState extends State<_OrchardCard> {
  Future<void> _showTreeSheet() async {
    final result = await showModalBottomSheet<_TreeChange>(
      context: context,
      builder: (_) => const _TreeChangeSheet(),
    );
    if (result == null) return;
    if (!mounted) return;
    final prov = context.read<CropsProvider>();
    if (result.delta > 0) {
      await prov.addTrees(widget.crop.id, result.delta);
    } else if (result.delta < 0) {
      await prov.markDeadTrees(widget.crop.id, -result.delta);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.crop;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.park_outlined, color: AppTheme.primaryGreen),
                const SizedBox(width: 8),
                Text(
                  context.tr(AppStrings.orchard, AppStrings.orchardBn),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _Pill(label: '${context.tr(AppStrings.total, AppStrings.totalBn)}: ${c.numberOfTrees}'),
                _Pill(
                  label: '${context.tr(AppStrings.newlyPlanted, AppStrings.newlyPlantedBn)}: ${c.newlyPlantedTrees}',
                  color: AppTheme.accentAmber,
                ),
                _Pill(
                  label: '${context.tr(AppStrings.dead, AppStrings.deadBn)}: ${c.deadTrees}',
                  color: AppTheme.danger,
                ),
                _Pill(
                  label: '${context.tr(AppStrings.live, AppStrings.liveBn)}: ${c.liveTrees}',
                  color: AppTheme.success,
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _showTreeSheet,
              icon: const Icon(Icons.edit_outlined),
              label: Text(context.tr(AppStrings.updateTrees, AppStrings.updateTreesBn)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, this.color = AppTheme.primaryGreen});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _TreeChange {
  const _TreeChange(this.delta);
  final int delta;
}

class _TreeChangeSheet extends StatefulWidget {
  const _TreeChangeSheet();

  @override
  State<_TreeChangeSheet> createState() => _TreeChangeSheetState();
}

class _TreeChangeSheetState extends State<_TreeChangeSheet> {
  bool _isDeath = false;
  final _count = TextEditingController(text: '1');

  @override
  void dispose() {
    _count.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tr(AppStrings.updateTrees, AppStrings.updateTreesBn),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: Text(
              _isDeath
                  ? context.tr(AppStrings.markDeadTrees, AppStrings.markDeadTreesBn)
                  : context.tr(AppStrings.addNewlyPlantedTrees, AppStrings.addNewlyPlantedTreesBn),
            ),
            value: _isDeath,
            onChanged: (v) => setState(() => _isDeath = v),
          ),
          TextField(
            controller: _count,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: context.tr(AppStrings.count, AppStrings.countBn)),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final n = int.tryParse(_count.text) ?? 0;
              if (n <= 0) return;
              Navigator.pop(context, _TreeChange(_isDeath ? -n : n));
            },
            child: Text(context.tr(AppStrings.save, AppStrings.saveBn)),
          ),
        ],
      ),
    );
  }
}

class _TimelineList extends StatelessWidget {
  const _TimelineList({required this.crop});
  final Crop crop;

  IconData _iconFor(String cat) {
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

  Color _colorFor(String cat) {
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

  @override
  Widget build(BuildContext context) {
    final activities = [...crop.activities]
      ..sort((a, b) => a.dayFromPlanting.compareTo(b.dayFromPlanting));
    if (activities.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(context.tr(AppStrings.noActivities, AppStrings.noActivitiesBn)),
        ),
      );
    }
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: activities.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final a = activities[i];
          return _TimelineRow(
            activity: a,
            isFirst: i == 0,
            isLast: i == activities.length - 1,
            icon: _iconFor(a.category),
            color: _colorFor(a.category),
            onToggle: (v) {
              context.read<CropsProvider>().toggleActivity(
                crop.id,
                a.id,
                v ?? false,
              );
              final updated = context
                  .read<CropsProvider>()
                  .crops
                  .where((c) => c.id == crop.id)
                  .firstOrNull;
              if (updated != null) {
                final prov = context.read<DailySuggestionsProvider>();
                if (!prov.hasFreshTodayRecord(crop.id)) {
                  prov.ensureToday(updated);
                }
              }
            },
          );
        },
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.activity,
    required this.isFirst,
    required this.isLast,
    required this.icon,
    required this.color,
    required this.onToggle,
  });

  final CropActivity activity;
  final bool isFirst;
  final bool isLast;
  final IconData icon;
  final Color color;
  final ValueChanged<bool?> onToggle;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final scheduled = DateTime(
      activity.scheduledDate.year,
      activity.scheduledDate.month,
      activity.scheduledDate.day,
    );
    final daysUntil = scheduled.difference(today).inDays;
    final isFuture = daysUntil > 0 && !activity.isCompleted;
    final isToday = daysUntil == 0;
    final isOverdue = daysUntil < 0 && !activity.isCompleted;

    // Task cannot be completed before its scheduled day starts
    final hasStarted = daysUntil <= 0;
    final canToggle = hasStarted || activity.isCompleted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isFuture ? color.withValues(alpha: 0.18) : color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isFuture ? Icons.lock_clock : icon,
              color: isFuture ? color : Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: canToggle
                  ? () => onToggle(!activity.isCompleted)
                  : () {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            context.isBn
                                ? 'এই কাজটি $daysUntil দিন পর (${activity.dayFromPlanting}তম দিন) শুরু হবে। শুরু হওয়ার আগে সম্পন্ন করা যাবে না!'
                                : 'This task starts in $daysUntil days (Day ${activity.dayFromPlanting}). It cannot be completed before it starts!',
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            activity.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              decoration: activity.isCompleted
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              color: isFuture
                                  ? AppTheme.textSecondary
                                  : AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        _CountdownChip(
                          daysUntil: daysUntil,
                          isToday: isToday,
                          isOverdue: isOverdue,
                          isCompleted: activity.isCompleted,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activity.description.isEmpty
                          ? '${context.isBn ? "${activity.dayFromPlanting}তম দিন" : "Day ${activity.dayFromPlanting}"} · ${Formatters.formatDate(scheduled, isBn: context.isBn)}'
                          : '${activity.description}\n${context.isBn ? "${activity.dayFromPlanting}তম দিন" : "Day ${activity.dayFromPlanting}"} · ${Formatters.formatDate(scheduled, isBn: context.isBn)}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (canToggle)
            Checkbox(
              value: activity.isCompleted,
              activeColor: AppTheme.primaryGreen,
              onChanged: onToggle,
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
                          ? 'এই কাজটি $daysUntil দিন পর (${activity.dayFromPlanting}তম দিন) শুরু হবে। শুরু হওয়ার আগে সম্পন্ন করা যাবে না!'
                          : 'This task starts in $daysUntil days (Day ${activity.dayFromPlanting}). It cannot be completed before it starts!',
                    ),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppTheme.accentAmber,
                    duration: const Duration(seconds: 3),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _CountdownChip extends StatelessWidget {
  const _CountdownChip({
    required this.daysUntil,
    required this.isToday,
    required this.isOverdue,
    required this.isCompleted,
  });

  final int daysUntil;
  final bool isToday;
  final bool isOverdue;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    IconData icon;
    if (isCompleted) {
      bg = AppTheme.success.withValues(alpha: 0.12);
      fg = AppTheme.success;
      label = context.tr('Done', 'সম্পন্ন');
      icon = Icons.check_circle;
    } else if (isToday) {
      bg = AppTheme.primaryGreen.withValues(alpha: 0.16);
      fg = AppTheme.primaryGreen;
      label = context.tr('Today', 'আজ');
      icon = Icons.today;
    } else if (daysUntil > 0) {
      bg = AppTheme.accentAmber.withValues(alpha: 0.14);
      fg = AppTheme.accentAmber;
      label = context.isBn
          ? (daysUntil == 1 ? '১ দিন পর' : '$daysUntil দিন পর')
          : (daysUntil == 1 ? 'in 1 day' : 'in $daysUntil days');
      icon = Icons.schedule;
    } else if (isOverdue) {
      final days = -daysUntil;
      bg = AppTheme.danger.withValues(alpha: 0.12);
      fg = AppTheme.danger;
      label = context.isBn
          ? (days == 1 ? '১ দিন বিলম্ব' : '$days দিন বিলম্ব')
          : (days == 1 ? '1 day overdue' : '$days days overdue');
      icon = Icons.warning_amber_rounded;
    } else {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
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
                    Text(
                      context.tr(AppStrings.aiAdviceTitle, AppStrings.aiAdviceTitleBn),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    if (suggestion != null) ...[
                      _SourceChip(source: suggestion.source),
                    ],
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
                  _SuggestionBody(
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

class _SuggestionBody extends StatelessWidget {
  const _SuggestionBody({
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
            if (stale) ...[
              const SizedBox(width: 8),
              _StaleBadge(onRefresh: () => prov.refreshFor(crop)),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(suggestion.guidance),
        if (suggestion.doItems.isNotEmpty) ...[
          const SizedBox(height: 12),
          _BulletList(
            title: context.tr(AppStrings.aiAdviceDo, AppStrings.aiAdviceDoBn),
            items: suggestion.doItems,
            color: AppTheme.success,
            icon: Icons.check_circle_outline,
          ),
        ],
        if (suggestion.dontItems.isNotEmpty) ...[
          const SizedBox(height: 8),
          _BulletList(
            title: context.tr(AppStrings.aiAdviceDont, AppStrings.aiAdviceDontBn),
            items: suggestion.dontItems,
            color: AppTheme.danger,
            icon: Icons.cancel_outlined,
          ),
        ],
      ],
    );
  }
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({required this.source});
  final String source;

  @override
  Widget build(BuildContext context) {
    final isFallback = source != 'gemini';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isFallback
            ? AppTheme.accentAmber.withValues(alpha: 0.18)
            : AppTheme.primaryGreen.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isFallback
            ? context.tr(AppStrings.aiAdviceSourceOffline, AppStrings.aiAdviceSourceOfflineBn)
            : context.tr(AppStrings.aiAdviceSourceGemini, AppStrings.aiAdviceSourceGeminiBn),
        style: TextStyle(
          color: isFallback ? AppTheme.accentAmber : AppTheme.primaryGreen,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _StaleBadge extends StatelessWidget {
  const _StaleBadge({required this.onRefresh});
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onRefresh,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppTheme.danger.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.refresh, size: 12, color: AppTheme.danger),
            const SizedBox(width: 4),
            Text(
              context.tr(AppStrings.aiAdviceStale, AppStrings.aiAdviceStaleBn),
              style: const TextStyle(
                color: AppTheme.danger,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BulletList extends StatelessWidget {
  const _BulletList({
    required this.title,
    required this.items,
    required this.color,
    required this.icon,
  });
  final String title;
  final List<String> items;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(color: color),
        ),
        const SizedBox(height: 4),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(item)),
              ],
            ),
          ),
      ],
    );
  }
}

class _TodaysTasksCard extends StatelessWidget {
  const _TodaysTasksCard({required this.crop});
  final Crop crop;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final overdue = <CropActivity>[];
    final dueToday = <CropActivity>[];
    final upcoming = <CropActivity>[];
    for (final a in crop.activities) {
      if (a.isCompleted) continue;
      final scheduled = DateTime(
        a.scheduledDate.year,
        a.scheduledDate.month,
        a.scheduledDate.day,
      );
      final days = scheduled.difference(today).inDays;
      if (days < 0) {
        overdue.add(a);
      } else if (days == 0) {
        dueToday.add(a);
      } else {
        upcoming.add(a);
      }
    }
    upcoming.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));

    final total = overdue.length + dueToday.length + upcoming.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.event_available_outlined,
                  color: AppTheme.primaryGreen,
                ),
                const SizedBox(width: 8),
                Text(
                  context.tr("Today's Tasks", "আজকের করণীয় কাজ"),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                if (total == 0)
                  Chip(
                    label: Text(context.tr('All caught up', 'সব কাজ সম্পন্ন!')),
                    backgroundColor: const Color(0xFFD7EFD9),
                    labelStyle: const TextStyle(color: AppTheme.success),
                  )
                else
                  Text(
                    context.isBn
                        ? '$totalটি কাজ বাকি'
                        : '$total ${total == 1 ? "task" : "tasks"} pending',
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _Bucket(
              icon: Icons.warning_amber_rounded,
              color: AppTheme.danger,
              title: context.tr('Overdue', 'বিলম্বিত কাজ'),
              items: overdue
                  .map(
                    (a) =>
                        '${a.title}  ·  ${Formatters.formatDate(a.scheduledDate, isBn: context.isBn)}',
                  )
                  .toList(growable: false),
              emptyText: context.tr('None — well done.', 'কোনো বিলম্বিত কাজ নেই।'),
            ),
            const SizedBox(height: 12),
            _Bucket(
              icon: Icons.today,
              color: AppTheme.primaryGreen,
              title: context.tr('Due Today', 'আজকের কাজ'),
              items: dueToday.map((a) => a.title).toList(growable: false),
              emptyText: context.tr('Nothing scheduled for today.', 'আজকের জন্য কোনো কাজ নির্ধারিত নেই।'),
            ),
            const SizedBox(height: 12),
            _Bucket(
              icon: Icons.schedule,
              color: AppTheme.accentAmber,
              title: context.tr('Upcoming', 'আসন্ন কাজ'),
              items: upcoming
                  .take(5)
                  .map(
                    (a) =>
                        '${a.title}  ·  ${Formatters.formatDate(a.scheduledDate, isBn: context.isBn)}',
                  )
                  .toList(growable: false),
              emptyText: context.tr('Nothing on the horizon.', 'সামনে কোনো কাজ নির্ধারিত নেই।'),
              footer: upcoming.length > 5
                  ? context.tr('+${upcoming.length - 5} more — see timeline below', '+${upcoming.length - 5}টি অতিরিক্ত — নিচে সময়রেখা দেখুন')
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _Bucket extends StatelessWidget {
  const _Bucket({
    required this.icon,
    required this.color,
    required this.title,
    required this.items,
    required this.emptyText,
    this.footer,
  });
  final IconData icon;
  final Color color;
  final String title;
  final List<String> items;
  final String emptyText;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              '${items.length}',
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (items.isEmpty)
          Text(emptyText, style: const TextStyle(color: AppTheme.textSecondary))
        else
          ...items.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(line),
            ),
          ),
        if (footer != null) ...[
          const SizedBox(height: 4),
          Text(
            footer!,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
        ],
      ],
    );
  }
}
