import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/layout/desktop_scope.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/header_action_bar.dart';
import '../../../../data/models/bd_crops_catalog.dart';
import '../../../../data/repositories/bd_crops_repository.dart';

class CropLibraryScreen extends StatefulWidget {
  const CropLibraryScreen({super.key});

  @override
  State<CropLibraryScreen> createState() => _CropLibraryScreenState();
}

class _CropLibraryScreenState extends State<CropLibraryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedCategory = 'All';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showGuidelineSheet(BuildContext context, CropCatalogEntry crop) {
    final isBn = context.read<LocaleProvider>().isBangla;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppTheme.primaryGreen,
                  child: Icon(Icons.eco, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isBn ? crop.nameBn : crop.nameEn,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${crop.scientificName} • ${crop.durationDays} ${isBn ? "দিন" : "Days"}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 20),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: AppTheme.primaryGreen, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${isBn ? "উপযোগী মৌসুম" : "Ideal Season"}: ${crop.idealSeason} | ${isBn ? "মাটি" : "Soil"}: ${crop.recommendedSoil}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            Text(
              isBn ? 'পূর্ণাঙ্গ চাষ ও পরিচর্যা নির্দেশিকা:' : 'Full Season Growth Guidelines:',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: crop.guidelines.isEmpty
                  ? Center(
                      child: Text(
                        isBn
                            ? 'এই ফসলের বিশেষ পরিচর্যা গাইডলাইন প্রক্রিয়াধীন রয়েছে।'
                            : 'Stage guidelines for this crop are updated regularly.',
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      itemCount: crop.guidelines.length,
                      itemBuilder: (context, index) {
                        final stage = crop.guidelines[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryGreen,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        'Day ${stage.dayStart}-${stage.dayEnd}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        isBn ? stage.stageNameBn : stage.stageNameEn,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  isBn ? stage.keyActivitiesBn : stage.keyActivitiesEn,
                                  style: const TextStyle(fontSize: 13, height: 1.3),
                                ),
                                if (stage.fertilizerAdviceBn.isNotEmpty || stage.waterAdviceBn.isNotEmpty || stage.pestPreventionBn.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  if (stage.fertilizerAdviceBn.isNotEmpty) ...[
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.science_outlined, size: 14, color: AppTheme.primaryGreen),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            '${isBn ? "সার ব্যবস্থাপনা" : "Fertilizer"}: ${stage.fertilizerAdviceBn}',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                  ],
                                  if (stage.waterAdviceBn.isNotEmpty) ...[
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.water_drop_outlined, size: 14, color: AppTheme.skyBlue),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            '${isBn ? "সেচ পরামর্শ" : "Irrigation"}: ${stage.waterAdviceBn}',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                  ],
                                  if (stage.pestPreventionBn.isNotEmpty) ...[
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.shield_outlined, size: 14, color: AppTheme.danger),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            '${isBn ? "বালাই দমন" : "Pest Protection"}: ${stage.pestPreventionBn}',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBn = context.watch<LocaleProvider>().isBangla;

    final filteredCrops = BdCropsRepository.allCrops.where((c) {
      final query = _searchCtrl.text.trim().toLowerCase();
      final matchesQuery = query.isEmpty ||
          c.nameBn.toLowerCase().contains(query) ||
          c.nameEn.toLowerCase().contains(query) ||
          c.scientificName.toLowerCase().contains(query);

      final matchesCategory = _selectedCategory == 'All' ||
          c.category.toLowerCase() == _selectedCategory.toLowerCase();

      return matchesQuery && matchesCategory;
    }).toList();

    final categories = ['All', 'Grains', 'Vegetables', 'Spices', 'Pulses', 'Fruits', 'Trees', 'Cash Crops'];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/app_logo.png',
              width: 26,
              height: 26,
              errorBuilder: (_, _, _) => const Icon(Icons.menu_book, size: 22),
            ),
            const SizedBox(width: 8),
            Text(
              context.tr(
                '50 Crops & Trees Directory',
                '৫০টি ফসল ও বৃক্ষ ডিরেক্টরি',
              ),
            ),
          ],
        ),
        actions: const [
          HeaderActionBar(),
          SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: isBn
                    ? 'ফসল বা গাছের নাম খুঁজুন... (e.g. আম, ধান, আলু)'
                    : 'Search 50 crops & trees...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {});
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: ChoiceChip(
                    label: Text(_categoryLabel(context, cat)),
                    selected: isSelected,
                    selectedColor: AppTheme.primaryGreen,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: filteredCrops.isEmpty
                ? Center(
                    child: Text(
                      isBn ? 'কোনো ফসল খুঁজে পাওয়া যায়নি' : 'No crops matching search query',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: DesktopScope.of(context)
                        ? const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 260,
                            childAspectRatio: 0.82,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                          )
                        : const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.82,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                    itemCount: filteredCrops.length,
                    itemBuilder: (context, index) {
                      final crop = filteredCrops[index];
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: AppTheme.primaryGreenLight.withValues(alpha: 0.2),
                                    child: const Icon(Icons.eco, color: AppTheme.primaryGreen, size: 20),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      isBn ? crop.nameBn : crop.nameEn,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${_categoryLabel(context, crop.category)} • ${crop.durationDays} ${context.tr("days", "দিন")}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isBn ? crop.descriptionBn : crop.descriptionEn,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, height: 1.2),
                              ),
                              const Spacer(),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () => _showGuidelineSheet(context, crop),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    minimumSize: const Size(0, 32),
                                  ),
                                  child: Text(
                                    isBn ? 'গাইডলাইন দেখুন' : 'Guideline',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _categoryLabel(BuildContext context, String cat) {
    if (!context.isBn) return cat;
    switch (cat) {
      case 'All':
        return 'সকল';
      case 'Grains':
        return 'দানা শস্য';
      case 'Vegetables':
        return 'শাকসবজি';
      case 'Spices':
        return 'মসলা জাতীয়';
      case 'Pulses':
        return 'ডাল জাতীয়';
      case 'Fruits':
        return 'ফলমূল';
      case 'Trees':
        return 'বৃক্ষ ও কাঠ';
      case 'Cash Crops':
        return 'অর্থকরী ফসল';
      default:
        return cat;
    }
  }
}
