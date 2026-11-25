import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/auth_gate.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/header_action_bar.dart';
import '../../../../data/models/animal.dart';
import '../providers/livestock_provider.dart';

class LivestockListScreen extends StatelessWidget {
  const LivestockListScreen({super.key});

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
              errorBuilder: (_, _, _) => const Icon(Icons.pets, size: 22),
            ),
            const SizedBox(width: 8),
            Text(
              context.tr(
                AppStrings.livestockList,
                AppStrings.livestockListBn,
              ),
            ),
          ],
        ),
        actions: [
          const HeaderActionBar(),
          Consumer<LivestockProvider>(
            builder: (context, prov, _) {
              return IconButton(
                tooltip: context.tr('Sync from cloud', 'ক্লাউড থেকে সিঙ্ক করুন'),
                icon: prov.isRefreshing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_sync_outlined),
                onPressed: prov.isRefreshing
                    ? null
                    : () => prov.refreshFromCloud(),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Consumer<LivestockProvider>(
            builder: (context, prov, _) {
              final ts = prov.lastSyncedAt;
              if (ts == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${context.tr("Last synced", "সর্বশেষ সিঙ্ক")}: ${Formatters.dateTime.format(ts)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      body: AuthGate(
        featureName: context.tr('livestock', 'গবাদিপশু ও পোল্ট্রি'),
        child: Consumer<LivestockProvider>(
          builder: (context, prov, _) {
            if (prov.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            final animals = prov.animals;
            if (animals.isEmpty) {
              return EmptyState(
                icon: Icons.pets,
                title: context.tr(AppStrings.noLivestockYet, AppStrings.noLivestockYetBn),
                subtitle: context.tr(
                  AppStrings.addYourFirstLivestock,
                  AppStrings.addYourFirstLivestockBn,
                ),
                action: ElevatedButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.addLivestock),
                  icon: const Icon(Icons.add),
                  label: Text(
                    context.tr(AppStrings.addLivestock, AppStrings.addLivestockBn),
                  ),
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: prov.refreshFromCloud,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _SummaryStrip(prov: prov),
                  const SizedBox(height: 12),
                  for (final a in animals) ...[
                    _AnimalCard(animal: a),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            Navigator.of(context).pushNamed(AppRoutes.addLivestock),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.prov});
  final LivestockProvider prov;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _Stat(
                icon: Icons.pets,
                label: context.tr(AppStrings.totalAnimals, AppStrings.totalAnimalsBn),
                value: '${prov.count}',
                color: AppTheme.primaryGreen,
              ),
            ),
            Expanded(
              child: _Stat(
                icon: Icons.favorite,
                label: context.tr(AppStrings.liveAnimals, AppStrings.liveAnimalsBn),
                value: '${prov.totalLiveCount}',
                color: AppTheme.success,
              ),
            ),
            Expanded(
              child: _Stat(
                icon: Icons.dangerous_outlined,
                label: context.tr(AppStrings.deadAnimals, AppStrings.deadAnimalsBn),
                value: '${prov.totalDeaths}',
                color: AppTheme.danger,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color),
        ),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

class _AnimalCard extends StatelessWidget {
  const _AnimalCard({required this.animal});
  final Animal animal;

  IconData _iconFor(String species) {
    switch (species) {
      case 'Poultry chicken':
      case 'Egg chicken':
        return Icons.set_meal;
      case 'Duck':
        return Icons.egg_outlined;
      case 'Cow':
        return Icons.agriculture;
      case 'Goat':
      case 'Sheep':
        return Icons.pets;
      default:
        return Icons.pets;
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = animal.daysSinceStart;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(
          context,
        ).pushNamed(AppRoutes.livestockDetail, arguments: animal.id),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.primaryGreenLight,
                    child: Icon(_iconFor(animal.species), color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          animal.species,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '${animal.purpose}  ·  ${Formatters.date.format(animal.startDate)}',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${context.tr("Day", "দিন")} $days',
                    style: const TextStyle(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _Pill(
                      icon: Icons.favorite,
                      color: AppTheme.success,
                      label: '${context.tr(AppStrings.liveAnimals, AppStrings.liveAnimalsBn)}: ${animal.liveCount}',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Pill(
                      icon: Icons.dangerous_outlined,
                      color: AppTheme.danger,
                      label: '${context.tr(AppStrings.deadAnimals, AppStrings.deadAnimalsBn)}: ${animal.deadCount}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _Pill(
                      icon: Icons.task_alt,
                      color: AppTheme.primaryGreen,
                      label:
                          '${animal.completedActivityCount}/${animal.activities.length} ${context.tr("done", "সম্পন্ন")}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pushNamed(
                        AppRoutes.livestockLiveTrack,
                        arguments: animal.id,
                      ),
                      icon: const Icon(Icons.monitor_heart_outlined, size: 18),
                      label: Text(
                        context.tr(AppStrings.liveTrack, AppStrings.liveTrackBn),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryGreen,
                        side: const BorderSide(color: AppTheme.primaryGreen),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pushNamed(
                        AppRoutes.livestockDetail,
                        arguments: animal.id,
                      ),
                      icon: const Icon(Icons.list_alt, size: 18),
                      label: Text(
                        context.tr(
                          AppStrings.livestockDetail,
                          AppStrings.livestockDetailBn,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary,
                        side: const BorderSide(color: AppTheme.divider),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.color, required this.label});
  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
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
