import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/header_action_bar.dart';
import '../../../../data/models/animal.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/livestock_activity_templates.dart';
import '../providers/livestock_provider.dart';

class AddLivestockScreen extends StatefulWidget {
  const AddLivestockScreen({super.key});

  @override
  State<AddLivestockScreen> createState() => _AddLivestockScreenState();
}

class _AddLivestockScreenState extends State<AddLivestockScreen> {
  final _formKey = GlobalKey<FormState>();
  String _species = AppConstants.livestockSpecies.first;
  String _purpose = AppConstants.defaultPurposeFor(
    AppConstants.livestockSpecies.first,
  );
  final _countCtrl = TextEditingController(text: '10');
  final _notesCtrl = TextEditingController();
  DateTime _startDate = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _countCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final uid = auth.user?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              'Please sign in first so this animal syncs to your account.',
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
      final id = DateTime.now().microsecondsSinceEpoch.toString();
      final animal = Animal(
        id: id,
        userId: uid,
        species: _species,
        purpose: _purpose,
        startDate: _startDate,
        totalCount: int.parse(_countCtrl.text.trim()),
        deadCount: 0,
        notes: _notesCtrl.text.trim(),
        activities: LivestockActivityTemplates.build(
          animalId: id,
          species: _species,
          purpose: _purpose,
          startDate: _startDate,
        ),
      );
      await context.read<LivestockProvider>().save(animal);
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
                    'Livestock Added Successfully!',
                    'গৃহপালিত পশু/হাঁস-মুরগি সফলভাবে যোগ করা হয়েছে!',
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
                    'Your livestock has been added to Live Tracking.',
                    'আপনার গৃহপালিত পশু/পাখির তথ্য লাইভ ট্র্যাকিং তালিকায় যুক্ত হয়েছে।',
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
              'Failed to save livestock. Please try again.',
              'পশু/হাঁস-মুরগি সংরক্ষণ ব্যর্থ হয়েছে। আবার চেষ্টা করুন।',
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
            Text(
              context.tr(
                AppStrings.addLivestock,
                AppStrings.addLivestockBn,
              ),
            ),
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
                    initialValue: _species,
                    decoration: InputDecoration(
                      labelText: context.tr(
                        AppStrings.livestockSpecies,
                        AppStrings.livestockSpeciesBn,
                      ),
                      prefixIcon: const Icon(Icons.pets),
                    ),
                    items: AppConstants.livestockSpecies
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(_localizeSpecies(context, s)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        _species = v;
                        final allowed = AppConstants.allowedPurposesForSpecies(
                          v,
                        );
                        final candidate = AppConstants.defaultPurposeFor(v);
                        _purpose = allowed.contains(candidate)
                            ? candidate
                            : (allowed.first);
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _purpose,
                    decoration: InputDecoration(
                      labelText: context.tr(
                        AppStrings.livestockPurpose,
                        AppStrings.livestockPurposeBn,
                      ),
                      prefixIcon: const Icon(Icons.flag_outlined),
                      helperText: context.tr(
                        'Realistic options for the chosen species',
                        'নির্বাচিত জাতের জন্য প্রযোজ্য উদ্দেশ্য',
                      ),
                    ),
                    items: AppConstants.allowedPurposesForSpecies(_species)
                        .map(
                          (p) => DropdownMenuItem(
                            value: p,
                            child: Text(_purposeLabel(context, p)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _purpose = v ?? _purpose),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _countCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: context.tr(
                        AppStrings.livestockTotalCount,
                        AppStrings.livestockTotalCountBn,
                      ),
                      prefixIcon: const Icon(Icons.numbers),
                    ),
                    validator: Validators.positiveNumber,
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: context.tr(
                          AppStrings.livestockStartDate,
                          AppStrings.livestockStartDateBn,
                        ),
                        prefixIcon: const Icon(Icons.calendar_today_outlined),
                      ),
                      child: Text(Formatters.date.format(_startDate)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: context.tr(AppStrings.notes, AppStrings.notesBn),
                      prefixIcon: const Icon(Icons.note_alt_outlined),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.save),
                    label: Text(
                      context.tr(AppStrings.saveAnimal, AppStrings.saveAnimalBn),
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

  String _localizeSpecies(BuildContext context, String s) {
    if (!context.isBn) return s;
    switch (s) {
      case 'Poultry chicken':
        return 'পোল্ট্রি মুরগি (Poultry chicken)';
      case 'Egg chicken':
        return 'ডিমপাড়া মুরগি (Egg chicken)';
      case 'Duck':
        return 'হাঁস (Duck)';
      case 'Cow':
        return 'গরু / গাভী (Cow)';
      case 'Goat':
        return 'ছাগল (Goat)';
      case 'Sheep':
        return 'ভেড়া (Sheep)';
      default:
        return s;
    }
  }

  String _purposeLabel(BuildContext context, String purpose) {
    if (!context.isBn) {
      switch (purpose) {
        case AppConstants.purposeMeat:
          return AppStrings.purposeMeat;
        case AppConstants.purposeEgg:
          return AppStrings.purposeEgg;
        case AppConstants.purposeDairy:
          return AppStrings.purposeDairy;
        case AppConstants.purposeMixed:
          return AppStrings.purposeMixed;
        default:
          return purpose;
      }
    } else {
      switch (purpose) {
        case AppConstants.purposeMeat:
          return AppStrings.purposeMeatBn;
        case AppConstants.purposeEgg:
          return AppStrings.purposeEggBn;
        case AppConstants.purposeDairy:
          return AppStrings.purposeDairyBn;
        case AppConstants.purposeMixed:
          return AppStrings.purposeMixedBn;
        default:
          return purpose;
      }
    }
  }
}
