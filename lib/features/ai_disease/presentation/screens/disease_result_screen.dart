import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/layout/adaptive_two_pane.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/header_action_bar.dart';
import '../../../../core/widgets/tts_readout_button.dart';
import '../providers/disease_detection_provider.dart';

class DiseaseResultScreen extends StatefulWidget {
  const DiseaseResultScreen({super.key});

  @override
  State<DiseaseResultScreen> createState() => _DiseaseResultScreenState();
}

class _DiseaseResultScreenState extends State<DiseaseResultScreen> {
  // Toggle between English and Bangla view
  bool _showBangla = true;

  @override
  void initState() {
    super.initState();
    // Default to app's current locale setting
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isBn = context.read<LocaleProvider>().isBangla;
      setState(() => _showBangla = isBn);
    });
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
              errorBuilder: (_, _, _) => const Icon(Icons.bug_report_outlined, size: 22),
            ),
            const SizedBox(width: 8),
            Text(_showBangla ? 'রোগ নির্ণয়ের ফলাফল' : 'Diagnosis Result'),
          ],
        ),
        actions: const [
          HeaderActionBar(),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Consumer<DiseaseDetectionProvider>(
          builder: (context, prov, _) {
            final r = prov.result;
            if (r == null) {
              return Center(
                child: Text(
                  _showBangla ? 'কোনো তথ্য নেই' : 'No diagnosis data available',
                ),
              );
            }

            final diseaseTitle = _showBangla
                ? (r.diseaseNameBn.isNotEmpty ? r.diseaseNameBn : r.diseaseName)
                : (r.diseaseNameEn.isNotEmpty ? r.diseaseNameEn : r.diseaseName);

            final cropTitle = _showBangla
                ? (r.cropNameBn.isNotEmpty ? r.cropNameBn : '')
                : (r.cropNameEn.isNotEmpty ? r.cropNameEn : '');

            final severityText = _showBangla
                ? (r.severityBn.isNotEmpty ? r.severityBn : r.severity)
                : r.severity;

            // Sequential step lists
            final symptomsSteps = _showBangla
                ? (r.symptomsStepsBn.isNotEmpty ? r.symptomsStepsBn : [if (r.symptoms.isNotEmpty) r.symptoms])
                : (r.symptomsStepsEn.isNotEmpty ? r.symptomsStepsEn : [if (r.symptoms.isNotEmpty) r.symptoms]);

            final treatmentSteps = _showBangla
                ? (r.treatmentStepsBn.isNotEmpty ? r.treatmentStepsBn : [if (r.treatment.isNotEmpty) r.treatment])
                : (r.treatmentStepsEn.isNotEmpty ? r.treatmentStepsEn : [if (r.treatment.isNotEmpty) r.treatment]);

            final preventionSteps = _showBangla
                ? (r.preventionStepsBn.isNotEmpty ? r.preventionStepsBn : [if (r.prevention.isNotEmpty) r.prevention])
                : (r.preventionStepsEn.isNotEmpty ? r.preventionStepsEn : [if (r.prevention.isNotEmpty) r.prevention]);

            final medicinesList = _showBangla
                ? (r.medicinesBn.isNotEmpty ? r.medicinesBn : [if (r.chemicalSolutions.isNotEmpty) r.chemicalSolutions])
                : (r.medicinesEn.isNotEmpty ? r.medicinesEn : [if (r.chemicalSolutions.isNotEmpty) r.chemicalSolutions]);

            final causesText = _showBangla
                ? (r.causesBn.isNotEmpty ? r.causesBn : r.causes)
                : (r.causesEn.isNotEmpty ? r.causesEn : r.causes);

            // Audio speech text for farmer convenience
            final treatmentSummary = treatmentSteps.isNotEmpty ? 'চিকিৎসা ধাপসমূহ: ${treatmentSteps.join('. ')}' : '';
            final ttsText = '$diseaseTitle। $treatmentSummary';

            return AdaptiveTwoPane(
              primary: [
                // Language Switcher Banner (English / বাংলা)
                _LanguageToggleBar(
                  isBangla: _showBangla,
                  onToggle: (val) => setState(() => _showBangla = val),
                ),
                const SizedBox(height: 12),

                // Diagnosis Header Card
                _DiagnosisHeaderCard(
                  diseaseTitle: diseaseTitle,
                  cropTitle: cropTitle,
                  confidence: r.confidence,
                  severity: severityText,
                  isBangla: _showBangla,
                  ttsText: ttsText,
                  imageBytesBase64: r.imageBytesBase64,
                ),
                const SizedBox(height: 14),

                // Causes
                if (causesText.trim().isNotEmpty)
                  _SimpleCard(
                    title: _showBangla ? 'রোগের কারণ ও পরিবেশ' : 'Causes & Environment',
                    icon: Icons.info_outline,
                    body: causesText,
                  ),

                // Sequential Symptoms
                if (symptomsSteps.isNotEmpty)
                  _SequentialStepsCard(
                    title: _showBangla ? 'লক্ষণসমূহ (পর্যায়ক্রমিক)' : 'Symptoms (Sequential)',
                    icon: Icons.visibility_outlined,
                    steps: symptomsSteps,
                    isBangla: _showBangla,
                    stepColor: Colors.blue.shade700,
                  ),

              ],
              secondary: [
                // Sequential Treatment Steps (Most critical for farmers)
                if (treatmentSteps.isNotEmpty)
                  _SequentialStepsCard(
                    title: _showBangla ? 'চিকিৎসা ও করণীয় (ধাপে ধাপে)' : 'Treatment & Action (Step-by-Step)',
                    icon: Icons.healing_outlined,
                    steps: treatmentSteps,
                    isBangla: _showBangla,
                    stepColor: AppTheme.primaryGreen,
                    isHighlight: true,
                  ),

                // Medicines & Pesticide Dosage
                if (medicinesList.isNotEmpty)
                  _SequentialStepsCard(
                    title: _showBangla ? 'প্রস্তাবিত ওষুধ ও প্রয়োগমাত্রা' : 'Recommended Medicines & Dosage',
                    icon: Icons.science_outlined,
                    steps: medicinesList,
                    isBangla: _showBangla,
                    stepColor: Colors.teal.shade700,
                  ),

                // Organic Solutions
                if (r.organicSolutions.trim().isNotEmpty)
                  _SimpleCard(
                    title: _showBangla ? 'জৈব সমাধান' : 'Organic / Biological Solutions',
                    icon: Icons.eco_outlined,
                    body: r.organicSolutions,
                  ),

                // Sequential Prevention Steps
                if (preventionSteps.isNotEmpty)
                  _SequentialStepsCard(
                    title: _showBangla ? 'ভবিষ্যৎ প্রতিরোধ ব্যবস্থা (ধাপে ধাপে)' : 'Prevention Measures (Step-by-Step)',
                    icon: Icons.shield_outlined,
                    steps: preventionSteps,
                    isBangla: _showBangla,
                    stepColor: Colors.indigo.shade700,
                  ),

                // Fallback Raw text
                if (r.rawText.trim().isNotEmpty &&
                    treatmentSteps.isEmpty &&
                    symptomsSteps.isEmpty)
                  _SimpleCard(
                    title: _showBangla ? 'পূর্ণ এআই উত্তর' : 'Full AI Response',
                    icon: Icons.chat_bubble_outline,
                    body: r.rawText,
                  ),

                const SizedBox(height: 20),

                // Back / Retake button
                OutlinedButton.icon(
                  onPressed: () {
                    prov.reset();
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: Text(
                    _showBangla ? 'আরেকটি ছবি স্ক্যান করুন' : 'Scan Another Photo',
                  ),
                ),
                const SizedBox(height: 12),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Language Selector Bar
class _LanguageToggleBar extends StatelessWidget {
  const _LanguageToggleBar({required this.isBangla, required this.onToggle});
  final bool isBangla;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.translate, size: 18, color: AppTheme.primaryGreen),
              const SizedBox(width: 8),
              Text(
                isBangla ? 'পরামর্শের ভাষা:' : 'Advice Language:',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Row(
            children: [
              ChoiceChip(
                label: const Text('বাংলা', style: TextStyle(fontSize: 12)),
                selected: isBangla,
                selectedColor: AppTheme.primaryGreenLight.withValues(alpha: 0.3),
                onSelected: (_) => onToggle(true),
              ),
              const SizedBox(width: 6),
              ChoiceChip(
                label: const Text('English', style: TextStyle(fontSize: 12)),
                selected: !isBangla,
                selectedColor: AppTheme.primaryGreenLight.withValues(alpha: 0.3),
                onSelected: (_) => onToggle(false),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Diagnosis Header Card with Confidence & TTS Voice Reader
class _DiagnosisHeaderCard extends StatelessWidget {
  const _DiagnosisHeaderCard({
    required this.diseaseTitle,
    required this.cropTitle,
    required this.confidence,
    required this.severity,
    required this.isBangla,
    required this.ttsText,
    this.imageBytesBase64 = '',
  });

  final String diseaseTitle;
  final String cropTitle;
  final double confidence;
  final String severity;
  final bool isBangla;
  final String ttsText;
  final String imageBytesBase64;

  @override
  Widget build(BuildContext context) {
    Uint8List? thumbBytes;
    if (imageBytesBase64.isNotEmpty) {
      try {
        thumbBytes = base64Decode(imageBytesBase64);
      } catch (_) {}
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (thumbBytes != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      thumbBytes,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              cropTitle.isNotEmpty
                                  ? cropTitle
                                  : (isBangla ? 'শনাক্তকৃত ফসল' : 'Detected Crop'),
                              style: const TextStyle(
                                color: AppTheme.primaryGreen,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Bangla / English Voice Readout Button
                          TtsReadoutButton(text: ttsText),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        diseaseTitle,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.green.shade900,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isBangla ? 'নির্ভুলতার হার' : 'Confidence',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${(confidence * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 26, color: Colors.grey.shade300),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isBangla ? 'তীব্রতার মাত্রা' : 'Severity',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        severity,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: severity.contains('High') || severity.contains('তীব্র')
                              ? Colors.red.shade700
                              : AppTheme.primaryGreenDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: confidence.clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Formats sequential steps (Step 1, Step 2, Step 3... / ধাপ ১, ধাপ ২, ধাপ ৩...)
/// into distinct step cards so farmers can easily follow along.
class _SequentialStepsCard extends StatelessWidget {
  const _SequentialStepsCard({
    required this.title,
    required this.icon,
    required this.steps,
    required this.isBangla,
    required this.stepColor,
    this.isHighlight = false,
  });

  final String title;
  final IconData icon;
  final List<String> steps;
  final bool isBangla;
  final Color stepColor;
  final bool isHighlight;

  String _toBengaliDigit(int number) {
    const en = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const bn = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    String s = number.toString();
    for (int i = 0; i < 10; i++) {
      s = s.replaceAll(en[i], bn[i]);
    }
    return s;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isHighlight ? 2 : 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isHighlight
            ? BorderSide(color: stepColor.withValues(alpha: 0.4), width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: stepColor, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isHighlight ? stepColor : null,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...steps.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              var stepText = entry.value.trim();

              // Remove redundant prefixes if already present in AI string
              stepText = stepText.replaceFirst(RegExp(r'^(Step\s*\d+:?|ধাপ\s*[\d০-৯]+:?)\s*', caseSensitive: false), '');

              final stepLabel = isBangla ? 'ধাপ ${_toBengaliDigit(idx)}' : 'Step $idx';

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: stepColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: stepColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        stepLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: stepColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        stepText,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _SimpleCard extends StatelessWidget {
  const _SimpleCard({required this.title, required this.icon, required this.body});
  final String title;
  final IconData icon;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.primaryGreen, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: const TextStyle(height: 1.45, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
