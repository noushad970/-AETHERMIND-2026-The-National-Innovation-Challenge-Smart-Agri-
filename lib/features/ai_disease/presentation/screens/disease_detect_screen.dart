import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/header_action_bar.dart';
import '../../../../data/models/disease_result.dart';
import '../providers/disease_detection_provider.dart';

class DiseaseDetectScreen extends StatefulWidget {
  const DiseaseDetectScreen({super.key});

  @override
  State<DiseaseDetectScreen> createState() => _DiseaseDetectScreenState();
}

class _DiseaseDetectScreenState extends State<DiseaseDetectScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DiseaseDetectionProvider>().refreshQuota();
    });
  }

  Future<void> _pick(ImageSource source, BuildContext context) async {
    final prov = context.read<DiseaseDetectionProvider>();
    if (!prov.canUpload) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(
            context.tr(
              'Daily limit reached (maximum 2 scans per day). Please try again tomorrow.',
              'আজকের দৈনিক সীমা (সর্বোচ্চ ২টি স্ক্যান) পূর্ণ হয়েছে। অনুগ্রহ করে আগামীকাল চেষ্টা করুন।',
            ),
          ),
        ),
      );
      return;
    }

    final picker = ImagePicker();
    try {
      final file = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1600,
      );
      if (file == null) return;
      final Uint8List bytes = await file.readAsBytes();
      if (!context.mounted) return;
      context.read<DiseaseDetectionProvider>().setImage(
        bytes,
        filename: file.name,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr('Could not load image: $e', 'ছবি লোড করা যায়নি: $e'),
          ),
        ),
      );
    }
  }

  void _analyze(BuildContext context) {
    final prov = context.read<DiseaseDetectionProvider>();
    if (!prov.canUpload) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(
            context.tr(
              'Daily scan limit reached. You can only analyze 2 images per day.',
              'আজকের দৈনিক সীমা শেষ। আপনি প্রতিদিন সর্বোচ্চ ২টি ফসলের ছবি পরীক্ষা করতে পারেন।',
            ),
          ),
        ),
      );
      return;
    }

    prov.detect().then((_) {
      if (!context.mounted) return;
      if (prov.result != null) {
        Navigator.of(context).pushNamed(AppRoutes.diseaseResult);
      } else if (prov.error != null) {
        final errText = context.read<LocaleProvider>().isBangla && prov.errorBn != null
            ? prov.errorBn!
            : prov.error!;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(
          backgroundColor: Colors.red.shade800,
          content: Text(errText),
        ));
      }
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
            Text(
              context.tr(
                AppStrings.aiDiseaseDetection,
                AppStrings.aiDiseaseDetectionBn,
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
        child: Consumer<DiseaseDetectionProvider>(
          builder: (context, prov, _) {
            final hasReachedLimit = !prov.canUpload;

            return Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Daily limit status card
                    _DailyQuotaCard(
                      remaining: prov.remainingScans,
                      limit: prov.dailyLimit,
                    ),
                    const SizedBox(height: 12),

                    Text(
                      context.tr(
                        AppStrings.uploadPhoto,
                        AppStrings.uploadPhotoBn,
                      ),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    const _ServerAIInfoBadge(),
                    const SizedBox(height: 16),

                    if (hasReachedLimit && prov.imageBytes == null)
                      _LimitReachedBanner()
                    else if (prov.imageBytes == null)
                      _PickerPlaceholder(
                        onCamera: () => _pick(ImageSource.camera, context),
                        onGallery: () => _pick(ImageSource.gallery, context),
                      )
                    else
                      _ImagePreview(
                        bytes: prov.imageBytes!,
                        onRetake: () => prov.setImage(null),
                      ),

                    const SizedBox(height: 16),

                    if (prov.error != null)
                      ErrorBanner(
                        message: context.read<LocaleProvider>().isBangla && prov.errorBn != null
                            ? prov.errorBn!
                            : prov.error!,
                      ),

                    ElevatedButton.icon(
                      onPressed: (prov.imageBytes == null || hasReachedLimit)
                          ? null
                          : () => _analyze(context),
                      icon: const Icon(Icons.psychology),
                      label: Text(
                        prov.isLoading
                            ? context.tr(AppStrings.analyzing, AppStrings.analyzingBn)
                            : hasReachedLimit
                                ? context.tr('Daily Limit Reached (2/2)', 'দৈনিক সীমা পূর্ণ (২/২)')
                                : context.tr('Analyze Plant Health', 'রোগ নির্ণয় শুরু করুন'),
                      ),
                    ),

                    if (prov.imageBytes != null)
                      TextButton.icon(
                        onPressed: () => prov.setImage(null),
                        icon: const Icon(Icons.refresh),
                        label: Text(
                          context.tr('Choose another photo', 'অন্য ছবি নির্বাচন করুন'),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Past scan reports from Hive local storage
                    if (prov.history.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.history, color: AppTheme.primaryGreen, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            context.tr('Previous Reports (Offline Cached)', 'পূর্ববর্তী স্ক্যান রিপোর্ট (অফলাইন সংরক্ষিত)'),
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...prov.history.take(5).map((scan) => _HistoryCard(scan: scan)),
                    ],
                  ],
                ),
                if (prov.isLoading)
                  const LoadingOverlay(
                    isLoading: true,
                    child: SizedBox.expand(),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Card showing remaining daily scans (max 2 per day)
class _DailyQuotaCard extends StatelessWidget {
  const _DailyQuotaCard({required this.remaining, required this.limit});
  final int remaining;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final used = (limit - remaining).clamp(0, limit);
    final isLimitReached = remaining <= 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isLimitReached ? Colors.orange.shade50 : AppTheme.primaryGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLimitReached ? Colors.orange.shade300 : AppTheme.primaryGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isLimitReached ? Icons.lock_clock : Icons.verified_user_outlined,
                    color: isLimitReached ? Colors.orange.shade800 : AppTheme.primaryGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.tr('Daily Scan Quota', 'দৈনিক স্ক্যান কোটা'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isLimitReached ? Colors.orange.shade900 : AppTheme.primaryGreenDark,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isLimitReached ? Colors.red.shade100 : AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  context.tr(
                    '$remaining of $limit remaining',
                    '$limit টির মধ্যে $remaining টি বাকি',
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isLimitReached ? Colors.red.shade900 : Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildSlotIndicator(
                context,
                slotNumber: 1,
                isUsed: used >= 1,
              ),
              const SizedBox(width: 10),
              _buildSlotIndicator(
                context,
                slotNumber: 2,
                isUsed: used >= 2,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            context.tr(
              'Each user can upload up to 2 plant disease images per day for maximum security and accuracy.',
              'নিরাপত্তা ও নির্ভুলতার জন্য প্রতি ব্যবহারকারী দৈনিক সর্বোচ্চ ২টি ফসলের ছবি আপলোড করতে পারবেন।',
            ),
            style: TextStyle(
              fontSize: 11,
              color: isLimitReached ? Colors.orange.shade900 : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotIndicator(BuildContext context, {required int slotNumber, required bool isUsed}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: isUsed ? Colors.grey.shade200 : AppTheme.primaryGreen.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isUsed ? Colors.grey.shade400 : AppTheme.primaryGreen,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUsed ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 16,
              color: isUsed ? Colors.grey.shade600 : AppTheme.primaryGreen,
            ),
            const SizedBox(width: 6),
            Text(
              context.tr('Scan $slotNumber', 'স্ক্যান $slotNumber') +
                  (isUsed ? context.tr(' (Used)', ' (ব্যবহৃত)') : context.tr(' (Available)', ' (উপলব্ধ)')),
              style: TextStyle(
                fontSize: 11,
                fontWeight: isUsed ? FontWeight.normal : FontWeight.bold,
                color: isUsed ? Colors.grey.shade600 : AppTheme.primaryGreenDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LimitReachedBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.amber.shade50,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.amber.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.info_outline, size: 48, color: Colors.amber),
            const SizedBox(height: 8),
            Text(
              context.tr('Daily Limit Reached', 'দৈনিক কোটা পূর্ণ'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              context.tr(
                'You have used all 2 disease scans for today. The quota automatically resets at midnight. You can view your saved past scans below anytime without internet!',
                'আজকের জন্য নির্ধারিত ২টি ছবি বিশ্লেষণের সুযোগ শেষ হয়েছে। রাত ১২টায় কোটা পুনরায় সচল হবে। পূর্ববর্তী ফলাফলগুলো নিচে অফলাইনেও দেখতে পারবেন।',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServerAIInfoBadge extends StatelessWidget {
  const _ServerAIInfoBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.security, color: AppTheme.primaryGreen, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(
                    'Smart Agri Dedicated Backend & Step-by-Step AI',
                    'স্মার্ট এগ্রি নিরাপদ সার্ভার ও পর্যায়ক্রমিক এআই পরামর্শ',
                  ),
                  style: const TextStyle(
                    color: AppTheme.primaryGreen,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr(
                    'All queries are processed through your dedicated backend server. Diagnosis is delivered in sequential steps (Step 1, Step 2...) in both English and Bangla.',
                    'আপনার অনুরোধসমূহ নিরাপদ সার্ভারের মাধ্যমে পরিচালিত। সমাধান জটিল টেক্সটের বদলে সহজ ধাপ ১, ধাপ ২ আকারে বাংলা ও ইংরেজিতে দেওয়া হয়।',
                  ),
                  style: const TextStyle(fontSize: 12, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerPlaceholder extends StatelessWidget {
  const _PickerPlaceholder({required this.onCamera, required this.onGallery});
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(
              Icons.image_outlined,
              size: 96,
              color: AppTheme.primaryGreenLight,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onCamera,
              icon: const Icon(Icons.camera_alt_outlined),
              label: Text(
                context.tr(
                  AppStrings.tapToTakePhoto,
                  AppStrings.tapToTakePhotoBn,
                ),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onGallery,
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(
                context.tr(
                  AppStrings.tapToChooseGallery,
                  AppStrings.tapToChooseGalleryBn,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.bytes, required this.onRetake});
  final Uint8List bytes;
  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Image.memory(
              bytes,
              fit: BoxFit.cover,
              height: 280,
              width: double.infinity,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextButton.icon(
              onPressed: onRetake,
              icon: const Icon(Icons.refresh),
              label: Text(context.tr('Retake', 'পুনরায় ছবি তুলুন')),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.scan});
  final DiseaseResult scan;

  @override
  Widget build(BuildContext context) {
    final isBn = context.watch<LocaleProvider>().isBangla;
    final title = isBn
        ? (scan.diseaseNameBn.isNotEmpty ? scan.diseaseNameBn : scan.diseaseName)
        : (scan.diseaseNameEn.isNotEmpty ? scan.diseaseNameEn : scan.diseaseName);

    Uint8List? thumbBytes;
    if (scan.imageBytesBase64.isNotEmpty) {
      try {
        thumbBytes = base64Decode(scan.imageBytesBase64);
      } catch (_) {}
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: thumbBytes != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.memory(thumbBytes, width: 44, height: 44, fit: BoxFit.cover),
              )
            : Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.eco_outlined, color: AppTheme.primaryGreen),
              ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          '${(scan.confidence * 100).toStringAsFixed(0)}% • ${scan.createdAt.day}/${scan.createdAt.month}/${scan.createdAt.year}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () {
          final prov = context.read<DiseaseDetectionProvider>();
          prov.selectFromHistory(scan);
          Navigator.of(context).pushNamed(AppRoutes.diseaseResult);
        },
      ),
    );
  }
}
