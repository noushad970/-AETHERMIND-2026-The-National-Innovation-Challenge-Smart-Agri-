import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/header_action_bar.dart';
import '../../../../data/repositories/bd_crops_repository.dart';
import '../../../../data/services/crop_template_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/crops_provider.dart';

class AddCropScreen extends StatefulWidget {
  const AddCropScreen({super.key});

  @override
  State<AddCropScreen> createState() => _AddCropScreenState();
}

class _AddCropScreenState extends State<AddCropScreen> {
  final _formKey = GlobalKey<FormState>();
  String _cropType = 'Boro Rice';

  final _varietyCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _treesCtrl = TextEditingController(text: '0');
  DateTime _plantingDate = DateTime.now();
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _varietyCtrl.dispose();
    _areaCtrl.dispose();
    _treesCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _plantingDate,
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _plantingDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final uid = auth.user?.uid;
    if (uid == null) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              'Please sign in first so this crop syncs to your account.',
              'আপনার অ্যাকাউন্টে সংরক্ষণ করতে অনুগ্রহ করে সাইন ইন করুন।',
            ),
          ),
        ),
      );
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      return;
    }

    setState(() => _saving = true);
    try {
      final crop = CropTemplateService.buildCrop(
        userId: uid,
        cropType: _cropType,
        variety: _varietyCtrl.text.trim(),
        plantingDate: _plantingDate,
        landAreaDecimal: double.parse(_areaCtrl.text),
        numberOfTrees: int.tryParse(_treesCtrl.text) ?? 0,
        notes: _notesCtrl.text.trim(),
      );
      await context.read<CropsProvider>().save(crop);
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            contentPadding: const EdgeInsets.all(24),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    size: 48,
                    color: Colors.green.shade600,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  context.tr(
                    'Crop Added Successfully!',
                    'ফসল সফলভাবে যোগ করা হয়েছে!',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  context.tr(
                    'Your crop has been added to Live Tracking.',
                    'আপনার নতুন ফসলটি সফলভাবে লাইভ ট্র্যাকিং তালিকায় যুক্ত হয়েছে।',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                    },
                    child: Text(
                      context.tr('Go to Homepage', 'হোমপেজে যান'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );

      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.home,
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            context.tr(
              'Failed to save crop. Please try again.',
              'ফসল সংরক্ষণ ব্যর্থ হয়েছে। আবার চেষ্টা করুন।',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOrchard = CropTemplateService.isOrchard(_cropType);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/app_logo.png',
              width: 26,
              height: 26,
              errorBuilder: (_, _, _) => const Icon(Icons.add_circle_outline, size: 22),
            ),
            const SizedBox(width: 8),
            Text(context.tr(AppStrings.addCrop, AppStrings.addCropBn)),
          ],
        ),
        actions: const [
          HeaderActionBar(),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: LoadingOverlay(
          isLoading: _saving,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _cropType,
                    decoration: InputDecoration(
                      labelText: context.tr(
                        AppStrings.cropType,
                        AppStrings.cropTypeBn,
                      ),
                      prefixIcon: const Icon(Icons.grass),
                    ),
                    items: BdCropsRepository.allCrops
                        .map((c) => DropdownMenuItem(
                              value: c.nameEn,
                              child: Text(
                                context.isBn
                                    ? '${c.nameBn} (${c.nameEn})'
                                    : '${c.nameEn} (${c.nameBn})',
                              ),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _cropType = v ?? 'Boro Rice'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _varietyCtrl,
                    decoration: InputDecoration(
                      labelText: context.tr(
                        AppStrings.variety,
                        AppStrings.varietyBn,
                      ),
                      prefixIcon: const Icon(Icons.spa_outlined),
                    ),
                    validator: Validators.required,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _areaCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: context.tr(
                        AppStrings.landAreaDecimal,
                        AppStrings.landAreaDecimalBn,
                      ),
                      prefixIcon: const Icon(Icons.straighten),
                      helperText: context.tr('in decimal (শতক)', 'শতকে পরিমাণ লিখুন'),
                    ),
                    validator: Validators.positiveNumber,
                  ),
                  if (isOrchard) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _treesCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: context.tr(
                          AppStrings.numberOfTrees,
                          AppStrings.numberOfTreesBn,
                        ),
                        prefixIcon: const Icon(Icons.park_outlined),
                      ),
                      validator: Validators.positiveNumber,
                    ),
                  ],
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: context.tr(
                          AppStrings.plantingDate,
                          AppStrings.plantingDateBn,
                        ),
                        prefixIcon: const Icon(Icons.calendar_today_outlined),
                      ),
                      child: Text(Formatters.date.format(_plantingDate)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: context.tr(
                        AppStrings.notes,
                        AppStrings.notesBn,
                      ),
                      prefixIcon: const Icon(Icons.note_alt_outlined),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.save),
                    label: Text(
                      context.tr(AppStrings.saveCrop, AppStrings.saveCropBn),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}