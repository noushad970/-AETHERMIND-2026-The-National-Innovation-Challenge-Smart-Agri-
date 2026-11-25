import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/locale_provider.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/agri_atmospheric_background.dart';
import '../../../../core/widgets/auth_gate.dart';
import '../providers/fish_provider.dart';

class FishDetailScreen extends StatelessWidget {
  const FishDetailScreen({super.key, required this.pondId});
  final String pondId;

  @override
  Widget build(BuildContext context) {
    final isBn = context.isBn;
    final fishProv = context.watch<FishProvider>();
    final pond = fishProv.getPond(pondId);

    if (pond == null) {
      return Scaffold(
        appBar: AppBar(title: Text(isBn ? 'পুকুর বিবরণ' : 'Pond Details')),
        body: Center(
          child: Text(isBn ? 'পুকুরের তথ্য পাওয়া যায়নি।' : 'Pond records not found.'),
        ),
      );
    }

    final species = pond.speciesData;

    return AuthGate(
      featureName: isBn ? 'মাছের পুকুর বিবরণ' : 'Fish Pond Details',
      child: Scaffold(
        appBar: AppBar(
          title: Text(pond.pondName),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.danger),
              tooltip: isBn ? 'পুকুর মুছুন' : 'Delete Pond',
              onPressed: () => _confirmDelete(context, pond.id, pond.pondName, isBn),
            ),
          ],
        ),
        body: AgriAtmosphericBackground(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Species Profile Card
              Container(
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
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00695C).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.set_meal_rounded, color: Color(0xFF00695C), size: 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isBn ? species.nameBn : species.nameEn,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              Text(
                                species.scientificName,
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00695C).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isBn ? species.categoryBn : species.category,
                            style: const TextStyle(
                              color: Color(0xFF00695C),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      species.descriptionBn,
                      style: const TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Pond Specs Card
              Container(
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
                      isBn ? 'পুকুরের প্রযুক্তিগত বিবরণ' : 'Pond Technical Specs',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    _SpecRow(
                      label: isBn ? 'আয়তন' : 'Area',
                      value: '${pond.pondAreaDecimals} ${isBn ? "শতক" : "decimals"}',
                    ),
                    _SpecRow(
                      label: isBn ? 'পানির গড় গভীরতা' : 'Water Depth',
                      value: '${pond.waterDepthFeet} ${isBn ? "ফুট" : "feet"}',
                    ),
                    _SpecRow(
                      label: isBn ? 'মজুদকৃত পোনা' : 'Stocked Count',
                      value: '${pond.fingerlingCount} ${isBn ? "টি" : "fingerlings"}',
                    ),
                    _SpecRow(
                      label: isBn ? 'মৃত মাছ' : 'Mortality',
                      value: '${pond.deadCount} ${isBn ? "টি" : "fish"}',
                    ),
                    _SpecRow(
                      label: isBn ? 'বর্তমান জীবিত মাছ' : 'Current Live Count',
                      value: '${pond.liveCount} ${isBn ? "টি" : "fish"}',
                    ),
                    _SpecRow(
                      label: isBn ? 'মজুদের তারিখ' : 'Stocking Date',
                      value: DateFormat('dd MMM yyyy').format(pond.stockingDate),
                    ),
                    _SpecRow(
                      label: isBn ? 'খাবারের ধরন' : 'Feed System',
                      value: pond.feedType.toUpperCase(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Feeding & Oxygen Advice Card
              Container(
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
                      isBn ? 'খাবার ও অক্সিজেন নির্দেশিকা' : 'Feeding & Aeration Guide',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      species.feedAdviceBn,
                      style: const TextStyle(fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00695C).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.pool_rounded, color: Color(0xFF00695C), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              species.swimmingAerationAdviceBn,
                              style: const TextStyle(fontSize: 12, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Live Tracking Action Button
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      AppRoutes.fishLiveTrack,
                      arguments: pond.id,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00695C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.track_changes_rounded),
                  label: Text(
                    isBn ? 'লাইভ ট্র্যাকিং ও পরামর্শ দেখুন' : 'View Live Tracking & Advice',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    String pondId,
    String pondName,
    bool isBn,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(isBn ? 'পুকুর মুছে ফেলতে চান?' : 'Delete Pond?'),
          content: Text(
            isBn
                ? 'আপনি কি নিশ্চিত যে "$pondName" পুকুরের সকল তথ্য ও ট্র্যাকিং মুছে ফেলতে চান?'
                : 'Are you sure you want to delete "$pondName" and all its records?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(isBn ? 'বাতিল' : 'Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.danger,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.of(ctx).pop();
                await context.read<FishProvider>().deletePond(pondId);
                if (context.mounted) Navigator.of(context).pop();
              },
              child: Text(isBn ? 'মুছে ফেলুন' : 'Delete'),
            ),
          ],
        );
      },
    );
  }
}

class _SpecRow extends StatelessWidget {
  const _SpecRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
