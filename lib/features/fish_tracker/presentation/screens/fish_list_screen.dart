import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/layout/adaptive_card_list.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/agri_atmospheric_background.dart';
import '../../../../core/widgets/auth_gate.dart';
import '../../../../data/models/fish_pond.dart';
import '../../../../data/services/feeding_alarm_service.dart';
import '../providers/fish_provider.dart';

class FishListScreen extends StatelessWidget {
  const FishListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isBn = context.isBn;

    return AuthGate(
      featureName: isBn
          ? 'মৎস্য চাষ ও লাইভ ট্র্যাকিং'
          : 'Fish Farming & Live Tracking',
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isBn ? '🐟 মৎস্য চাষ ও পুকুর ট্র্যাকার' : '🐟 Fish Pond Live Tracker',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.alarm_on_rounded),
              tooltip: isBn ? 'খাবারের অ্যালার্ম' : 'Feeding Alarm',
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.settings),
            ),
          ],
        ),
        body: AgriAtmosphericBackground(
          child: Consumer<FishProvider>(
            builder: (context, fishProv, _) {
              if (fishProv.isLoading && fishProv.ponds.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryGreen,
                  ),
                );
              }

              final ponds = fishProv.ponds;

              if (ponds.isEmpty) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const _FishFeedingAlarmBanner(),
                    const SizedBox(height: 16),
                    _EmptyFishView(isBn: isBn),
                  ],
                );
              }

              return AdaptiveCardList(
                minItemWidth: 420,
                header: [
                  _FishSummaryHeader(
                    totalPonds: fishProv.totalPonds,
                    totalLiveFish: fishProv.totalLiveFish,
                    isBn: isBn,
                  ),
                  const SizedBox(height: 12),
                  const _FishFeedingAlarmBanner(),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isBn ? 'আপনার সক্রিয় পুকুরসমূহ' : 'Your Active Ponds',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        '${ponds.length} ${isBn ? "টি পুকুর" : "ponds"}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                itemCount: ponds.length,
                itemBuilder: (context, i) =>
                    _FishPondCard(pond: ponds[i], isBn: isBn),
                // Keeps the last card clear of the add button.
                footer: const [SizedBox(height: 72)],
              );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.of(context).pushNamed(AppRoutes.addFish),
          backgroundColor: const Color(0xFF00695C),
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: Text(
            isBn ? 'নতুন পুকুর যোগ করুন' : 'Add New Pond',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class _FishSummaryHeader extends StatelessWidget {
  const _FishSummaryHeader({
    required this.totalPonds,
    required this.totalLiveFish,
    required this.isBn,
  });

  final int totalPonds;
  final int totalLiveFish;
  final bool isBn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00695C), Color(0xFF00897B), Color(0xFF0277BD)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00695C).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.water_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Text(
                isBn ? 'মৎস্য খামার ড্যাশবোর্ড' : 'Aquaculture Dashboard',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: isBn ? 'মোট পুকুর' : 'Total Ponds',
                  value: '$totalPonds',
                  icon: Icons.grid_view_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricTile(
                  label: isBn ? 'জীবিত মাছের সংখ্যা' : 'Live Fish Count',
                  value: '$totalLiveFish',
                  icon: Icons.set_meal_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _FishPondCard extends StatelessWidget {
  const _FishPondCard({required this.pond, required this.isBn});
  final FishPond pond;
  final bool isBn;

  @override
  Widget build(BuildContext context) {
    final species = pond.speciesData;
    final progress = (pond.progress * 100).toStringAsFixed(0);

    return InkWell(
      onTap: () {
        Navigator.of(context).pushNamed(
          AppRoutes.fishLiveTrack,
          arguments: pond.id,
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFF00695C).withValues(alpha: 0.15),
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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00695C).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.set_meal_rounded,
                    color: Color(0xFF00695C),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pond.pondName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        isBn ? species.nameBn : species.nameEn,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00695C).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$progress%',
                    style: const TextStyle(
                      color: Color(0xFF00695C),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: pond.progress,
                minHeight: 6,
                backgroundColor: const Color(0xFF00695C).withValues(alpha: 0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF00897B),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _InfoChip(
                  icon: Icons.calendar_today_rounded,
                  text: '${pond.daysSinceStocking} ${isBn ? "দিন চাষ" : "days"}',
                ),
                _InfoChip(
                  icon: Icons.groups_rounded,
                  text: '${pond.liveCount} ${isBn ? "টি মাছ" : "fish"}',
                ),
                _InfoChip(
                  icon: Icons.aspect_ratio_rounded,
                  text: '${pond.pondAreaDecimals} ${isBn ? "শতক" : "dec"}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _EmptyFishView extends StatelessWidget {
  const _EmptyFishView({required this.isBn});
  final bool isBn;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF00695C).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.set_meal_rounded,
                size: 64,
                color: Color(0xFF00695C),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              isBn
                  ? 'কোনো সক্রিয় মাছের পুকুর নেই'
                  : 'No Active Fish Ponds Tracked',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              isBn
                  ? 'বাংলাদেশের শীর্ষ ২০টি জনপ্রিয় পুকুরের মাছের লাইভ ট্র্যাকিং, দৈনন্দিন খাবার ও সাঁতার কেটে অক্সিজেন সঞ্চালন শুরু করুন।'
                  : 'Track culture progress, daily feeding alarms & pond swimming oxygen aeration for top 20 Bangladesh pond fishes.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.addFish),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00695C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.add),
              label: Text(
                isBn ? 'পুকুরে মাছের পোনা যুক্ত করুন' : 'Add First Fish Pond',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FishFeedingAlarmBanner extends StatelessWidget {
  const _FishFeedingAlarmBanner();

  @override
  Widget build(BuildContext context) {
    final isBn = context.isBn;
    final alarmService = context.watch<FeedingAlarmService>();
    final isPlaying = alarmService.isPlayingAlarm;
    final isEnabled = alarmService.alarmsEnabled;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00695C).withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
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
                child: const Icon(
                  Icons.alarm_on_rounded,
                  color: Color(0xFF00695C),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isBn ? '⏰ মাছের খাবার অ্যালার্ম সূচি' : '⏰ Fish Feeding Alarm Schedule',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      isBn
                          ? 'সকাল ০৮:০০ ও বিকাল ০৪:৩০ (বাংলাদেশ সময়)'
                          : '08:00 AM & 04:30 PM (BST)',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
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
          const SizedBox(height: 10),
          if (isPlaying) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              child: ElevatedButton.icon(
                onPressed: () async {
                  await alarmService.stopAlarmAudio();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.danger,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.stop_circle_rounded, size: 20),
                label: Text(
                  isBn ? '🚨 অ্যালার্ম বন্ধ করুন (Stop Alarm)' : '🚨 Stop Fish Alarm Now',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.volume_up_rounded, size: 16),
                  label: Text(
                    isBn ? 'অ্যালার্ম পরীক্ষা' : 'Test Fish Alarm',
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
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    elevation: isPlaying ? 2 : 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.stop_rounded, size: 16),
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

