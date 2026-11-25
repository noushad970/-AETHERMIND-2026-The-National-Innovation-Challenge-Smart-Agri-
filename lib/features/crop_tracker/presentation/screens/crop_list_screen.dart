import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/layout/adaptive_card_list.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/agri_atmospheric_background.dart';
import '../../../../core/widgets/auth_gate.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/header_action_bar.dart';
import '../../../../data/models/crop.dart';
import '../providers/crops_provider.dart';

class CropListScreen extends StatelessWidget {
  const CropListScreen({super.key});

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
              errorBuilder: (_, _, _) => const Icon(Icons.eco_outlined, size: 22),
            ),
            const SizedBox(width: 8),
            Text(context.tr(AppStrings.myCrops, AppStrings.myCropsBn)),
          ],
        ),
        actions: [
          const HeaderActionBar(),
          Consumer<CropsProvider>(
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
          child: Consumer<CropsProvider>(
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
      body: AgriAtmosphericBackground(
        child: AuthGate(
          featureName: context.tr('the crop tracker', 'ফসল ট্র্যাকার'),
          child: Consumer<CropsProvider>(
            builder: (context, prov, _) {
              if (prov.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              final crops = prov.crops;
              if (crops.isEmpty) {
                return EmptyState(
                  icon: Icons.eco,
                  title: context.tr(
                    AppStrings.noCropsYet,
                    AppStrings.noCropsYetBn,
                  ),
                  subtitle: context.tr(
                    AppStrings.addYourFirstCrop,
                    AppStrings.addYourFirstCropBn,
                  ),
                  action: ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.of(context).pushNamed(AppRoutes.addCrop),
                    icon: const Icon(Icons.add),
                    label: Text(
                      context.tr(AppStrings.addCrop, AppStrings.addCropBn),
                    ),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: prov.refreshFromCloud,
                child: AdaptiveCardList(
                  minItemWidth: 420,
                  itemCount: crops.length,
                  itemBuilder: (context, i) => _CropCard(crop: crops[i]),
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.addCrop),
        icon: const Icon(Icons.add),
        label: Text(
          context.tr(AppStrings.addCrop, AppStrings.addCropBn),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _CropCard extends StatelessWidget {
  const _CropCard({required this.crop});
  final Crop crop;

  void _openLiveTrack(BuildContext context) {
    Navigator.of(
      context,
    ).pushNamed(AppRoutes.cropLiveTrack, arguments: crop.id);
  }

  @override
  Widget build(BuildContext context) {
    final progress = (crop.progress * 100).toStringAsFixed(0);
    final stage = crop.currentGrowthStage;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _openLiveTrack(context),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppTheme.primaryGreenLight,
                          AppTheme.primaryGreen,
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${crop.daysSincePlanting}${context.tr("d", "দিন")}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          crop.cropType,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${crop.variety} • ${Formatters.date.format(crop.plantingDate)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        if (stage.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.spa,
                                size: 12,
                                color: AppTheme.primaryGreen,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                stage,
                                style: const TextStyle(
                                  color: AppTheme.primaryGreen,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$progress%',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: crop.progress,
                  minHeight: 6,
                  backgroundColor:
                      AppTheme.primaryGreenLight.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation(
                    AppTheme.primaryGreen,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '📍 ${crop.landAreaDecimal.toStringAsFixed(1)} ${context.tr("decimal", "শতক")}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.tr(
                          AppStrings.liveTrack,
                          AppStrings.liveTrackBn,
                        ),
                        style: const TextStyle(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 12,
                        color: AppTheme.primaryGreen,
                      ),
                    ],
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
