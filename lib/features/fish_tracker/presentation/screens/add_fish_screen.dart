import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/providers/locale_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/agri_atmospheric_background.dart';
import '../../../../core/widgets/auth_gate.dart';
import '../../../../data/models/bd_fishes_catalog.dart';
import '../../../../data/models/fish_pond.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/fish_activity_templates.dart';
import '../providers/fish_provider.dart';

class AddFishScreen extends StatefulWidget {
  const AddFishScreen({super.key});

  @override
  State<AddFishScreen> createState() => _AddFishScreenState();
}

class _AddFishScreenState extends State<AddFishScreen> {
  final _formKey = GlobalKey<FormState>();

  BdFishSpecies _selectedSpecies = BdFishesCatalog.top20Fishes.first;
  final _pondNameCtrl = TextEditingController(text: 'প্রধান পুকুর (Main Pond)');
  final _areaCtrl = TextEditingController(text: '২০');
  final _fingerlingCtrl = TextEditingController(text: '১০০০');
  final _depthCtrl = TextEditingController(text: '৪.৫');
  final _harvestDaysCtrl = TextEditingController(text: '১৮০');
  final _notesCtrl = TextEditingController();

  DateTime _stockingDate = DateTime.now();
  String _feedType = 'floating';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _harvestDaysCtrl.text = '${_selectedSpecies.typicalGrowthDays}';
  }

  @override
  void dispose() {
    _pondNameCtrl.dispose();
    _areaCtrl.dispose();
    _fingerlingCtrl.dispose();
    _depthCtrl.dispose();
    _harvestDaysCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _onSpeciesChanged(BdFishSpecies s) {
    setState(() {
      _selectedSpecies = s;
      _harvestDaysCtrl.text = '${s.typicalGrowthDays}';
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _stockingDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF00695C),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _stockingDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final isBn = context.read<LocaleProvider>().isBangla;
    final auth = context.read<AuthProvider>();
    final fishProv = context.read<FishProvider>();

    try {
      final pondId = const Uuid().v4();
      final area = double.tryParse(_areaCtrl.text.trim()) ?? 20.0;
      final count = int.tryParse(_fingerlingCtrl.text.trim()) ?? 1000;
      final depth = double.tryParse(_depthCtrl.text.trim()) ?? 4.5;
      final harvestDays =
          int.tryParse(_harvestDaysCtrl.text.trim()) ??
          _selectedSpecies.typicalGrowthDays;

      final activities = FishActivityTemplates.generateForPond(
        fishPondId: pondId,
        speciesId: _selectedSpecies.id,
        stockingDate: _stockingDate,
        targetHarvestDays: harvestDays,
      );

      final pond = FishPond(
        id: pondId,
        userId: auth.user?.uid ?? '',
        speciesId: _selectedSpecies.id,
        speciesName: _selectedSpecies.nameBn,
        pondName: _pondNameCtrl.text.trim().isNotEmpty
            ? _pondNameCtrl.text.trim()
            : (isBn ? 'পুকুর' : 'Pond'),
        pondAreaDecimals: area,
        fingerlingCount: count,
        stockingDate: _stockingDate,
        targetHarvestDays: harvestDays,
        feedType: _feedType,
        waterDepthFeet: depth,
        notes: _notesCtrl.text.trim(),
        activities: activities,
      );

      await fishProv.addPond(pond);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.primaryGreen,
          content: Text(
            isBn
                ? 'মাছের পুকুর ও দৈনন্দিন রুটিন সফলভাবে যুক্ত হয়েছে!'
                : 'Fish pond & daily schedule successfully added!',
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.danger,
          content: Text(
            isBn ? 'সংরক্ষণ ব্যর্থ হয়েছে: $e' : 'Failed to save: $e',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBn = context.isBn;

    return AuthGate(
      featureName: isBn ? 'নতুন মাছের পুকুর যোগ' : 'Add New Fish Pond',
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isBn ? 'নতুন মাছের পুকুর যোগ করুন' : 'Add New Fish Pond',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: AgriAtmosphericBackground(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Top 20 Fishes Selector Card
                _SpeciesSelectionCard(
                  selectedSpecies: _selectedSpecies,
                  onSelected: _onSpeciesChanged,
                  isBn: isBn,
                ),
                const SizedBox(height: 16),

                // Pond details Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(18),
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
                        isBn ? 'পুকুরের সাধারণ তথ্য' : 'Pond Information',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Pond Name
                      TextFormField(
                        controller: _pondNameCtrl,
                        decoration: InputDecoration(
                          labelText: isBn ? 'পুকুরের নাম / নম্বর' : 'Pond Name / ID',
                          prefixIcon: const Icon(Icons.drive_file_rename_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty
                                ? (isBn ? 'পুকুরের নাম দিন' : 'Enter pond name')
                                : null,
                      ),
                      const SizedBox(height: 14),

                      // Pond area & Depth row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _areaCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: isBn ? 'আয়তন (শতক)' : 'Area (decimal)',
                                prefixIcon: const Icon(Icons.aspect_ratio_rounded),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (v) =>
                                  v == null || v.trim().isEmpty
                                      ? (isBn ? 'আয়তন দিন' : 'Enter area')
                                      : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _depthCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: isBn ? 'পানির গভীরতা (ফুট)' : 'Depth (feet)',
                                prefixIcon: const Icon(Icons.height_rounded),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Fingerling count & Harvest Days
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _fingerlingCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: isBn ? 'পোনার সংখ্যা' : 'Fingerlings',
                                prefixIcon: const Icon(Icons.groups_rounded),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (v) =>
                                  v == null || v.trim().isEmpty
                                      ? (isBn ? 'সংখ্যা দিন' : 'Enter count')
                                      : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _harvestDaysCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: isBn ? 'চাষকাল (দিন)' : 'Culture Days',
                                prefixIcon: const Icon(Icons.timer_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Stocking Date Picker
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_month_rounded, color: Color(0xFF00695C)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isBn ? 'পোনা মজুদের তারিখ' : 'Stocking Date',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      DateFormat('dd MMMM yyyy').format(_stockingDate),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Feed Type Selector
                      DropdownButtonFormField<String>(
                        initialValue: _feedType,
                        decoration: InputDecoration(
                          labelText: isBn ? 'খাবারের ধরন' : 'Feed Type',
                          prefixIcon: const Icon(Icons.fastfood_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'floating',
                            child: Text(isBn ? 'ভাসমান পিলেট ফিড (Floating)' : 'Floating Pellet Feed'),
                          ),
                          DropdownMenuItem(
                            value: 'sinking',
                            child: Text(isBn ? 'ডুবন্ত দানাদার ফিড (Sinking)' : 'Sinking Feed'),
                          ),
                          DropdownMenuItem(
                            value: 'homemade',
                            child: Text(isBn ? 'খৈল-কুঁড়া-ঘাস (Homemade Mix)' : 'Homemade Mustard Oil Cake & Bran'),
                          ),
                          DropdownMenuItem(
                            value: 'mixed',
                            child: Text(isBn ? 'মিশ্র পদ্ধতি (Commercial + Local)' : 'Mixed Floating & Bran'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _feedType = v);
                        },
                      ),
                      const SizedBox(height: 14),

                      // Notes
                      TextFormField(
                        controller: _notesCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: isBn ? 'মন্তব্য / পুকুরের বিশেষ তথ্য (ঐচ্ছিক)' : 'Notes (Optional)',
                          prefixIcon: const Icon(Icons.note_alt_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Save button
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00695C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.check_circle_rounded),
                    label: Text(
                      _saving
                          ? (isBn ? 'সংরক্ষণ করা হচ্ছে...' : 'Saving...')
                          : (isBn ? 'পুকুর ট্র্যাকিং শুরু করুন' : 'Start Pond Live Tracking'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SpeciesSelectionCard extends StatelessWidget {
  const _SpeciesSelectionCard({
    required this.selectedSpecies,
    required this.onSelected,
    required this.isBn,
  });

  final BdFishSpecies selectedSpecies;
  final ValueChanged<BdFishSpecies> onSelected;
  final bool isBn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
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
                isBn ? 'বাংলাদেশের শীর্ষ ২০ মাছের তালিকা' : 'Top 20 BD Fishes',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00695C).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '২০টি প্রজাতি',
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
          DropdownButtonFormField<BdFishSpecies>(
            initialValue: selectedSpecies,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: isBn ? 'মাছের জাত নির্বাচন করুন' : 'Select Fish Species',
              prefixIcon: const Icon(Icons.set_meal_rounded, color: Color(0xFF00695C)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: BdFishesCatalog.top20Fishes.map((f) {
              return DropdownMenuItem<BdFishSpecies>(
                value: f,
                child: Text(
                  '${f.nameBn} (${f.nameEn})',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              );
            }).toList(),
            onChanged: (v) {
              if (v != null) onSelected(v);
            },
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF00695C).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Color(0xFF00695C)),
                    const SizedBox(width: 6),
                    Text(
                      isBn ? selectedSpecies.categoryBn : selectedSpecies.category,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00695C),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  selectedSpecies.descriptionBn,
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.alarm, size: 14, color: AppTheme.sunYellow),
                    const SizedBox(width: 4),
                    Text(
                      '${isBn ? "খাবারের সময়" : "Feed Times"}: ${selectedSpecies.optimalFeedingTimes.join(", ")} (BST)',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
