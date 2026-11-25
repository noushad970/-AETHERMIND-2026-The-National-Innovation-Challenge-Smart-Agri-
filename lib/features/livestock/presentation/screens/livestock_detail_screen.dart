import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/layout/adaptive_two_pane.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/header_action_bar.dart';
import '../../../../data/models/animal.dart';

import '../../../../data/models/livestock_daily_suggestion.dart';
import '../../../../data/repositories/livestock_repository.dart';
import '../providers/livestock_daily_suggestions_provider.dart';
import '../providers/livestock_provider.dart';

/// Detailed view for a single animal group. Shows the species
/// overview, today's checklist with overdue support, the AI daily
/// guidance card, and quick "record today's data" actions.
class LivestockDetailScreen extends StatelessWidget {
  const LivestockDetailScreen({super.key, required this.animalId});
  final String animalId;

  @override
  Widget build(BuildContext context) {
    return Consumer<LivestockProvider>(
      builder: (context, prov, _) {
        final animal = prov.byId(animalId);
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
                    errorBuilder: (_, _, _) => const Icon(Icons.pets, size: 22),
                  ),
                  const SizedBox(width: 8),
                  Text(context.tr(AppStrings.livestockDetail, AppStrings.livestockDetailBn)),
                ],
              ),
              actions: const [
                HeaderActionBar(),
                SizedBox(width: 8),
              ],
            ),
            body: EmptyState(
              icon: Icons.error_outline,
              title: context.tr('Animal not found', 'প্রাণী খুঁজে পাওয়া যায়নি'),
            ),
          );
        }
        return _DetailScaffold(animal: animal);
      },
    );
  }
}

class _DetailScaffold extends StatefulWidget {
  const _DetailScaffold({required this.animal});
  final Animal animal;

  @override
  State<_DetailScaffold> createState() => _DetailScaffoldState();
}

class _DetailScaffoldState extends State<_DetailScaffold> {
  late final LivestockRepository _repo;

  @override
  void initState() {
    super.initState();
    _repo = LivestockRepository();
    // Load the most recent summary from the Firestore cache and prime
    // today's suggestion card. Only call Gemini when today's record
    // is genuinely missing — same-day reopens read the Firestore doc.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final summary = _repo.getLatestSummaryFor(widget.animal.id);
      final prov = context.read<LivestockDailySuggestionsProvider>();
      prov.primeFromCache(widget.animal.id);
      if (!prov.hasFreshTodayRecord(widget.animal.id)) {
        await prov.ensureToday(widget.animal, summary);
      }
    });
  }

  Future<void> _confirmDelete() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.tr(AppStrings.deleteAnimal, AppStrings.deleteAnimalBn)),
        content: Text(
          context.tr(
            'Delete this ${widget.animal.species} group? This cannot be undone.',
            'আপনি কি এই ${widget.animal.species} দলটি মুছে ফেলতে চান?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr(AppStrings.cancel, AppStrings.cancelBn)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              context.tr(AppStrings.delete, AppStrings.deleteBn),
              style: const TextStyle(color: AppTheme.danger),
            ),
          ),
        ],
      ),
    );
    if (yes == true) {
      if (!mounted) return;
      final provider = context.read<LivestockProvider>();
      final navigator = Navigator.of(context);
      await provider.delete(widget.animal.id);
      if (!mounted) return;
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final animal = widget.animal;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/app_logo.png',
              width: 26,
              height: 26,
              errorBuilder: (_, _, _) => const Icon(Icons.pets, size: 22),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                animal.species,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          const HeaderActionBar(),
          IconButton(
            tooltip: context.tr(AppStrings.liveTrack, AppStrings.liveTrackBn),
            icon: const Icon(Icons.monitor_heart_outlined),
            onPressed: () => Navigator.of(
              context,
            ).pushNamed(AppRoutes.livestockLiveTrack, arguments: animal.id),
          ),
          IconButton(
            tooltip: context.tr(AppStrings.deleteAnimal, AppStrings.deleteAnimalBn),
            icon: const Icon(Icons.delete_outline),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: Consumer<LivestockProvider>(
        builder: (context, prov, _) {
          // Re-read to pick up activity toggles / death records.
          final live = prov.byId(animal.id) ?? animal;
          return AdaptiveTwoPane(
            primary: [
              _OverviewCard(animal: live),
              const SizedBox(height: 12),
              _DailyActionsCard(animal: live),
              const SizedBox(height: 12),
              _TodayChecklistCard(animal: live),
              const SizedBox(height: 12),
            ],
            secondary: [
              _AiAdviceCard(animal: live, repo: _repo),
              const SizedBox(height: 12),
              _RecentDeathsCard(animal: live, repo: _repo),
              const SizedBox(height: 12),
              _TimelineCard(animal: live),
            ],
          );
        },
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.animal});
  final Animal animal;

  @override
  Widget build(BuildContext context) {
    final days = animal.daysSinceStart;
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
                        context.isBn
                            ? '${animal.purpose}  ·  $daysতম দিন'
                            : '${animal.purpose}  ·  Day $days',
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Formatters.formatDate(animal.startDate, isBn: context.isBn),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppTheme.primaryGreen,
                  child: Text(
                    '${animal.totalCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _Pill(
                    color: AppTheme.success,
                    icon: Icons.favorite,
                    label: '${context.tr(AppStrings.liveAnimals, AppStrings.liveAnimalsBn)}: ${animal.liveCount}',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Pill(
                    color: AppTheme.danger,
                    icon: Icons.dangerous_outlined,
                    label: '${context.tr(AppStrings.deadAnimals, AppStrings.deadAnimalsBn)}: ${animal.deadCount}',
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

class _Pill extends StatelessWidget {
  const _Pill({required this.color, required this.icon, required this.label});
  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyActionsCard extends StatelessWidget {
  const _DailyActionsCard({required this.animal});
  final Animal animal;

  Future<void> _openSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _SummarySheet(animal: animal),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.event_note, color: AppTheme.primaryGreen),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.tr(AppStrings.recordDailySummary, AppStrings.recordDailySummaryBn),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _openSheet(context),
              icon: const Icon(Icons.add, size: 18),
              label: Text(
                context.tr(AppStrings.recordDailySummary, AppStrings.recordDailySummaryBn),
                overflow: TextOverflow.ellipsis,
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                minimumSize: const Size(0, 40),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummarySheet extends StatefulWidget {
  const _SummarySheet({required this.animal});
  final Animal animal;

  @override
  State<_SummarySheet> createState() => _SummarySheetState();
}

class _SummarySheetState extends State<_SummarySheet> {
  final _deathsCtrl = TextEditingController(text: '0');
  final _eggsCtrl = TextEditingController(text: '0');
  final _milkCtrl = TextEditingController(text: '0');
  final _feedCtrl = TextEditingController(text: '0');
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _deathsCtrl.dispose();
    _eggsCtrl.dispose();
    _milkCtrl.dispose();
    _feedCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final animal = widget.animal;
    final deaths = int.tryParse(_deathsCtrl.text.trim()) ?? 0;
    final eggs = int.tryParse(_eggsCtrl.text.trim()) ?? 0;
    final milk = double.tryParse(_milkCtrl.text.trim()) ?? 0;
    final feed = double.tryParse(_feedCtrl.text.trim()) ?? 0;
    final notes = _notesCtrl.text.trim();
    final repo = LivestockRepository();
    final summary = await repo.saveDailySummary(
      animalId: animal.id,
      deaths: deaths,
      eggsToday: animal.producesEggs ? eggs : 0,
      milkLitersToday: animal.producesMilk ? milk : 0,
      feedKg: feed,
      notes: notes,
    );
    if (mounted) {
      final savedMsg = context.tr('Daily summary saved.', 'দৈনিক বিবরণ সংরক্ষিত হয়েছে।');
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(savedMsg)));
      await context.read<LivestockDailySuggestionsProvider>().refreshFor(
        animal,
        summary,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final animal = widget.animal;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr(AppStrings.recordDailySummary, AppStrings.recordDailySummaryBn),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _deathsCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: context.tr(AppStrings.deathsCount, AppStrings.deathsCountBn),
                prefixIcon: const Icon(Icons.dangerous_outlined),
              ),
            ),
            const SizedBox(height: 12),
            if (animal.producesEggs) ...[
              TextField(
                controller: _eggsCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: context.tr(AppStrings.eggsToday, AppStrings.eggsTodayBn),
                  prefixIcon: const Icon(Icons.egg_outlined),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (animal.producesMilk) ...[
              TextField(
                controller: _milkCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: context.tr(AppStrings.milkLitersToday, AppStrings.milkLitersTodayBn),
                  prefixIcon: const Icon(Icons.local_drink_outlined),
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _feedCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: context.tr(AppStrings.feedKgToday, AppStrings.feedKgTodayBn),
                prefixIcon: const Icon(Icons.scale_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: context.tr(AppStrings.notes, AppStrings.notesBn),
                prefixIcon: const Icon(Icons.note_alt_outlined),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save),
              label: Text(context.tr(AppStrings.save, AppStrings.saveBn)),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiAdviceCard extends StatelessWidget {
  const _AiAdviceCard({required this.animal, required this.repo});
  final Animal animal;
  final LivestockRepository repo;

  @override
  Widget build(BuildContext context) {
    return Consumer<LivestockDailySuggestionsProvider>(
      builder: (context, prov, _) {
        final suggestion = prov.suggestionFor(animal.id);
        final loading = prov.isLoading(animal.id);
        final error = prov.errorFor(animal.id);
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
                      context.tr(AppStrings.livestockAiAdviceTitle, AppStrings.livestockAiAdviceTitleBn),
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
                          : () {
                              final summary = repo.getLatestSummaryFor(
                                animal.id,
                              );
                              prov.refreshFor(animal, summary);
                            },
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
                  _AdviceBody(
                    suggestion: suggestion,
                    animal: animal,
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

class _AdviceBody extends StatelessWidget {
  const _AdviceBody({
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
                '${context.isBn ? "${suggestion.dayFromStart}তম দিন" : "Day ${suggestion.dayFromStart}"}  ·  ${suggestion.dateKey}',
                style: const TextStyle(
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            if (stale) ...[
              const SizedBox(width: 8),
              _StaleBadge(
                onRefresh: () {
                  final repo = LivestockRepository();
                  final summary = repo.getLatestSummaryFor(animal.id);
                  prov.refreshFor(animal, summary);
                },
              ),
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

class _RecentDeathsCard extends StatelessWidget {
  const _RecentDeathsCard({required this.animal, required this.repo});
  final Animal animal;
  final LivestockRepository repo;

  @override
  Widget build(BuildContext context) {
    final summaries = repo.getSummariesForAnimal(animal.id)
      ..sort((a, b) => b.dateKey.compareTo(a.dateKey));
    final recent = summaries.take(5).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, color: AppTheme.primaryGreen),
                const SizedBox(width: 8),
                Text(
                  context.tr(AppStrings.lastSummary, AppStrings.lastSummaryBn),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (recent.isEmpty)
              Text(
                context.tr(AppStrings.noSummaryYet, AppStrings.noSummaryYetBn),
                style: const TextStyle(color: AppTheme.textSecondary),
              )
            else
              for (final s in recent)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: Text(
                          s.dateKey,
                          style: const TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            _Pill(
                              color: AppTheme.success,
                              icon: Icons.favorite,
                              label:
                                  '${context.tr(AppStrings.liveAnimals, AppStrings.liveAnimalsBn)}: ${s.liveCount}',
                            ),
                            _Pill(
                              color: AppTheme.danger,
                              icon: Icons.dangerous_outlined,
                              label: '${context.tr("Died", "মৃত")}: ${s.deathsToday}',
                            ),
                            if (animal.producesEggs)
                              _Pill(
                                color: AppTheme.accentAmber,
                                icon: Icons.egg_outlined,
                                label: '${context.tr("Eggs", "ডিম")}: ${s.eggsToday}',
                              ),
                            if (animal.producesMilk)
                              _Pill(
                                color: AppTheme.skyBlue,
                                icon: Icons.local_drink_outlined,
                                label:
                                    '${context.tr("Milk", "দুধ")}: ${s.milkLitersToday.toStringAsFixed(1)}${context.tr("L", "লিটার")}',
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.animal});
  final Animal animal;

  @override
  Widget build(BuildContext context) {
    final acts = [...animal.activities]
      ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
    if (acts.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(context.tr(AppStrings.noActivities, AppStrings.noActivitiesBn)),
        ),
      );
    }
    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(
                  Icons.event_available_outlined,
                  color: AppTheme.primaryGreen,
                ),
                const SizedBox(width: 8),
                Text(
                  context.tr(AppStrings.livestockActivityTimeline, AppStrings.livestockActivityTimelineBn),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: acts.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) => _TimelineRow(
              activity: acts[i],
              isFirst: i == 0,
              isLast: i == acts.length - 1,
              onToggle: (v) {
                context.read<LivestockProvider>().toggleActivity(
                  animal.id,
                  acts[i].id,
                  v ?? false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.activity,
    required this.isFirst,
    required this.isLast,
    required this.onToggle,
  });

  final LivestockActivity activity;
  final bool isFirst;
  final bool isLast;
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
    final color = _colorFor(activity.category);

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
              isFuture ? Icons.lock_clock : _iconFor(activity.category),
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
                                ? 'এই কাজটি $daysUntil দিন পর (${activity.dayFromStart}তম দিন) শুরু হবে। শুরু হওয়ার আগে সম্পন্ন করা যাবে না!'
                                : 'This task starts in $daysUntil days (Day ${activity.dayFromStart}). It cannot be completed before it starts!',
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
                            activity.getTitle(context.isBn),
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
                      activity.getDescription(context.isBn).isEmpty
                          ? '${context.isBn ? "${activity.dayFromStart}তম দিন" : "Day ${activity.dayFromStart}"}  ·  ${Formatters.formatDate(scheduled, isBn: context.isBn)}'
                          : '${activity.getDescription(context.isBn)}\n${context.isBn ? "${activity.dayFromStart}তম দিন" : "Day ${activity.dayFromStart}"}  ·  ${Formatters.formatDate(scheduled, isBn: context.isBn)}',
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
                          ? 'এই কাজটি $daysUntil দিন পর (${activity.dayFromStart}তম দিন) শুরু হবে। শুরু হওয়ার আগে সম্পন্ন করা যাবে না!'
                          : 'This task starts in $daysUntil days (Day ${activity.dayFromStart}). It cannot be completed before it starts!',
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

  IconData _iconFor(String cat) {
    switch (cat) {
      case AppConstants.lcatFeeding:
        return Icons.restaurant;
      case AppConstants.lcatWater:
        return Icons.water_drop_outlined;
      case AppConstants.lcatCleaning:
        return Icons.cleaning_services_outlined;
      case AppConstants.lcatVaccination:
        return Icons.vaccines_outlined;
      case AppConstants.lcatHealth:
        return Icons.medical_services_outlined;
      case AppConstants.lcatEggCollect:
        return Icons.egg_outlined;
      case AppConstants.lcatMilk:
        return Icons.local_drink_outlined;
      case AppConstants.lcatWeighing:
        return Icons.scale_outlined;
      default:
        return Icons.task_alt;
    }
  }

  Color _colorFor(String cat) {
    switch (cat) {
      case AppConstants.lcatFeeding:
        return AppTheme.earthBrown;
      case AppConstants.lcatWater:
        return AppTheme.skyBlue;
      case AppConstants.lcatCleaning:
        return AppTheme.accentAmber;
      case AppConstants.lcatVaccination:
        return AppTheme.primaryGreen;
      case AppConstants.lcatHealth:
        return AppTheme.danger;
      case AppConstants.lcatEggCollect:
        return AppTheme.accentAmber;
      case AppConstants.lcatMilk:
        return AppTheme.skyBlue;
      case AppConstants.lcatWeighing:
        return AppTheme.primaryGreenLight;
      default:
        return AppTheme.primaryGreen;
    }
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

class _TodayChecklistCard extends StatelessWidget {
  const _TodayChecklistCard({required this.animal});
  final Animal animal;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final rows = <LivestockActivity>[];
    for (final a in animal.activities) {
      final d = DateTime(
        a.scheduledDate.year,
        a.scheduledDate.month,
        a.scheduledDate.day,
      );
      final diff = d.difference(today).inDays;
      if (diff <= 0 && !a.isCompleted) {
        rows.add(a);
      }
    }
    rows.sort((a, b) {
      if (a.repeatIntervalDays != b.repeatIntervalDays) {
        return b.repeatIntervalDays.compareTo(a.repeatIntervalDays);
      }
      return a.scheduledDate.compareTo(b.scheduledDate);
    });
    final completedToday = animal.activities.where((a) {
      if (!a.isCompleted) return false;
      final c = a.completedAt;
      if (c == null) return false;
      return c.year == now.year && c.month == now.month && c.day == now.day;
    }).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.checklist_rtl, color: AppTheme.primaryGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr(AppStrings.todaysChecklist, AppStrings.todaysChecklistBn),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (rows.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$completedToday / ${rows.length + completedToday}',
                      style: const TextStyle(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (rows.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  context.tr(AppStrings.todaysChecklistEmpty, AppStrings.todaysChecklistEmptyBn),
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
              )
            else
              for (var i = 0; i < rows.length; i++)
                _TodayChecklistRow(
                  activity: rows[i],
                  isLast: i == rows.length - 1,
                  onToggle: (v) {
                    context.read<LivestockProvider>().toggleActivity(
                      animal.id,
                      rows[i].id,
                      v ?? false,
                    );
                  },
                ),
          ],
        ),
      ),
    );
  }
}

class _TodayChecklistRow extends StatelessWidget {
  const _TodayChecklistRow({
    required this.activity,
    required this.isLast,
    required this.onToggle,
  });

  final LivestockActivity activity;
  final bool isLast;
  final ValueChanged<bool?> onToggle;

  @override
  Widget build(BuildContext context) {
    final dueLabel = _dueLabel(context, activity);
    return Column(
      children: [
        CheckboxListTile(
          value: activity.isCompleted,
          onChanged: onToggle,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Row(
            children: [
              Expanded(
                child: Text(
                  activity.getTitle(context.isBn),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              if (activity.repeatIntervalDays > 0)
                _RecurringBadge(days: activity.repeatIntervalDays),
            ],
          ),
          subtitle: Text(
            dueLabel,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
        ),
        if (!isLast) const Divider(height: 1),
      ],
    );
  }

  String _dueLabel(BuildContext context, LivestockActivity a) {
    final desc = a.getDescription(context.isBn);
    if (desc.isNotEmpty) return desc;
    final d = a.scheduledDate;
    return Formatters.formatDate(d, isBn: context.isBn);
  }
}

class _RecurringBadge extends StatelessWidget {
  const _RecurringBadge({required this.days});
  final int days;

  @override
  Widget build(BuildContext context) {
    final isDaily = days == 1;
    final label = isDaily
        ? context.tr(AppStrings.recurringBadgeDaily, AppStrings.recurringBadgeDailyBn)
        : days == 7
            ? context.tr(AppStrings.recurringBadgeWeekly, AppStrings.recurringBadgeWeeklyBn)
            : context.tr('Every $days d', 'প্রতি $days দিন');
    final color = isDaily ? AppTheme.primaryGreen : AppTheme.accentAmber;
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isDaily ? Icons.today : Icons.date_range,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
