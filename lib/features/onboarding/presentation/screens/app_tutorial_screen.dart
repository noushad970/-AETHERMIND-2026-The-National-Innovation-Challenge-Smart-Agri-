import 'package:flutter/material.dart';

import '../../../../core/providers/locale_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/header_action_bar.dart';

/// Standalone Tutorial / App Guide screen that users can view anytime
/// from the Home menu or App Settings.
class AppTutorialScreen extends StatefulWidget {
  const AppTutorialScreen({super.key});

  @override
  State<AppTutorialScreen> createState() => _AppTutorialScreenState();
}

class _AppTutorialScreenState extends State<AppTutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 5;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBn = context.isBn;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/app_logo.png',
              width: 26,
              height: 26,
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.menu_book_outlined, size: 22),
            ),
            const SizedBox(width: 8),
            Text(
              context.tr('App Guide & Tutorial', 'অ্যাপ ব্যবহার নির্দেশিকা'),
            ),
          ],
        ),
        actions: const [
          HeaderActionBar(),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildTutorialSlide(
                    context: context,
                    icon: Icons.eco,
                    iconColor: AppTheme.primaryGreen,
                    tagBn: 'ধাপ ১: স্মার্ট ফসল ট্র্যাকিং',
                    tagEn: 'Step 1: Smart Crop Tracking',
                    titleBn: 'বীজ বপন থেকে ফসল তোলা পর্যন্ত নিখুঁত গাইড',
                    titleEn: 'Track Crops from Sowing to Harvest',
                    descBn:
                        'আপনার ফসলের ধরন ও জাত নির্বাচন করে যোগ করুন। প্রতিদিনের করণীয় কাজের তালিকা, সার ও সেচের পরামর্শ এবং এআই অ্যাসিস্ট্যান্টের লাইভ নির্দেশনা পান।',
                    descEn:
                        'Add your crop variety and follow stage-by-stage growth timelines. Get automated daily task checklists and AI-driven growth guidance.',
                    bulletPointsBn: const [
                      'প্রতিটি ধাপের জন্য নির্দিষ্ট কাজের তালিকা',
                      'সার ও কীটনাশক প্রয়োগের সঠিক সময়সূচি',
                      'পরিকল্পিত ফলন ও লাইভ ট্র্যাকিং',
                    ],
                    bulletPointsEn: const [
                      'Stage-by-stage customized checklists',
                      'Optimal fertilizer & pesticide timings',
                      'Harvest tracking & progress monitoring',
                    ],
                  ),
                  _buildTutorialSlide(
                    context: context,
                    icon: Icons.pets,
                    iconColor: AppTheme.accentAmber,
                    tagBn: 'ধাপ ২: গবাদি পশু ও পোল্ট্রি পালন',
                    tagEn: 'Step 2: Livestock & Poultry Manager',
                    titleBn: 'পশুর স্বাস্থ্য ও খামারের উৎপাদন বৃদ্ধি',
                    titleEn: 'Monitor Herd Health & Production',
                    descBn:
                        'গরু, ছাগল বা মুরগির সংখ্যা, প্রজনন, খাদ্য তালিকা, ডিম উৎপাদন ও মৃত্যুর হিসাব রাখুন। সময়মতো ভ্যাকসিন ও কৃমিনাশক অ্যালার্ট পান।',
                    descEn:
                        'Manage cattle, goats, or poultry. Log daily feeding, egg production, mortality, and receive automated vaccination schedules.',
                    bulletPointsBn: const [
                      'স্বয়ংক্রিয় ভ্যাকসিন ও কৃমিনাশক শিডিউল',
                      'দৈনিক ডিম ও মাংস উৎপাদন ট্র্যাকিং',
                      'এআই ভেটেরিনারি স্বাস্থ্য ও যত্ন পরামর্শ',
                    ],
                    bulletPointsEn: const [
                      'Automated vaccination & deworming alerts',
                      'Daily egg & weight tracking logs',
                      'AI veterinary care suggestions',
                    ],
                  ),
                  _buildTutorialSlide(
                    context: context,
                    icon: Icons.camera_alt_outlined,
                    iconColor: Colors.deepOrange,
                    tagBn: 'ধাপ ৩: এআই রোগ নির্ণয় (AI Doctor)',
                    tagEn: 'Step 3: AI Disease Diagnosis',
                    titleBn: 'আক্রান্ত পাতার ছবি তুলে তাৎক্ষণিক চিকিৎসা',
                    titleEn: 'Snap Leaf Photos for Instant Diagnosis',
                    descBn:
                        'ফসলের রোগাক্রান্ত পাতার ছবি তুলুন বা গ্যালারি থেকে আপলোড করুন। গুগল জেমিনি এআই স্বয়ংক্রিয়ভাবে রোগ শনাক্ত করে লক্ষণ ও জৈব/রাসায়নিক সমাধান জানাবে।',
                    descEn:
                        'Take a photo of diseased leaves or stems. Google Gemini AI accurately identifies the issue, causes, organic treatments, and chemical cures.',
                    bulletPointsBn: const [
                      '৯৫%+ সঠিকতায় রোগ শনাক্তকরণ',
                      'জৈব ও রাসায়নিক উভয় প্রতিকার ব্যবস্থা',
                      'ভবিষ্যতে রোগ প্রতিরোধের পূর্বপ্রস্তুতি',
                    ],
                    bulletPointsEn: const [
                      'High-accuracy instant disease detection',
                      'Both organic & chemical remedy guides',
                      'Preventive actions to protect harvest',
                    ],
                  ),
                  _buildTutorialSlide(
                    context: context,
                    icon: Icons.water_drop,
                    iconColor: AppTheme.skyBlue,
                    tagBn: 'ধাপ ৪: স্মার্ট সেচ ও আবহাওয়া সতর্কতা',
                    tagEn: 'Step 4: Smart Irrigation & Weather',
                    titleBn: 'মাটির আর্দ্রতা ও আবহাওয়া অনুযায়ী সেচ',
                    titleEn: 'Precise Watering & Storm Alerts',
                    descBn:
                        'মাটির ধরন ও তাপমাত্রা মিলিয়ে পানির সঠিক হিসাব পান। ভারী বৃষ্টি, তাপপ্রবাহ বা ঝড়ের পূর্ব সতর্কবার্তা নিয়ে ফসল রক্ষা করুন।',
                    descEn:
                        'Calculate exact soil moisture needs and get hyperlocal 7-day weather forecasts to avoid over-watering and prepare for storms.',
                    bulletPointsBn: const [
                      'মাটির ধরন অনুযায়ী সেচ ক্যালকুলেটর',
                      'স্থানীয় ৭ দিনের আবহাওয়ার পূর্বাভাস',
                      'ঝড় ও বৃষ্টির তাৎক্ষণিক নোটিফিকেশন',
                    ],
                    bulletPointsEn: const [
                      'Soil-type specific watering calculator',
                      '7-day hyperlocal Open-Meteo forecast',
                      'Instant storm & rain alert popups',
                    ],
                  ),
                  _buildTutorialSlide(
                    context: context,
                    icon: Icons.hub_outlined,
                    iconColor: AppTheme.earthBrown,
                    tagBn: 'ধাপ ৫: কৃষি বাজার, কমিউনিটি ও ১৬১২৩',
                    tagEn: 'Step 5: Market Prices, Feed & 16123',
                    titleBn: 'সরাসরি বিশেষজ্ঞ কল ও কৃষকদের কমিউনিটি',
                    titleEn: 'Market Rates, Feed & 16123 Helpline',
                    descBn:
                        '৬৪ জেলার বাজার দর দেখুন, খামারের আয়-ব্যয় সংরক্ষণ করুন, অন্য কৃষকদের সাথে টিপস শেয়ার করুন এবং সরাসরি কৃষি হেল্পলাইন ১৬১২৩ এ কল করুন।',
                    descEn:
                        'Check real-time market wholesale rates, record farm income/expenses, share posts in community feed, and call the 16123 national helpline.',
                    bulletPointsBn: const [
                      'জাতীয় কৃষি কল সেন্টার ১৬১২৩ এ সরাসরি কল',
                      '৬৪ জেলার কৃষি কর্মকর্তার ফোন ডিরেক্টরি',
                      'কৃষক কমিউনিটি ফিডে পোস্ট ও অভিজ্ঞতা শেয়ার',
                    ],
                    bulletPointsEn: const [
                      'One-tap call to National 16123 Helpline',
                      '64-District Agricultural Officer directory',
                      'Share farming updates & questions in Feed',
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_totalPages, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppTheme.primaryGreen
                              : AppTheme.divider,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (_currentPage > 0)
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          onPressed: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: const Icon(Icons.arrow_back),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              if (_currentPage < _totalPages - 1) {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              } else {
                                Navigator.of(context).pop();
                              }
                            },
                            child: Text(
                              _currentPage == _totalPages - 1
                                  ? (isBn ? 'টিউটোরিয়াল সম্পন্ন ও হোমে ফিরুন' : 'Complete Tutorial & Return')
                                  : (isBn ? 'পরবর্তী ধাপ' : 'Next Step'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTutorialSlide({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String tagBn,
    required String tagEn,
    required String titleBn,
    required String titleEn,
    required String descBn,
    required String descEn,
    required List<String> bulletPointsBn,
    required List<String> bulletPointsEn,
  }) {
    final isBn = context.isBn;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isBn ? tagBn : tagEn,
              style: TextStyle(
                color: iconColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 64,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isBn ? titleBn : titleEn,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isBn ? descBn : descEn,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Column(
              children: List.generate(
                bulletPointsBn.length,
                (i) => Padding(
                  padding: EdgeInsets.only(
                    bottom: i < bulletPointsBn.length - 1 ? 10 : 0,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: iconColor,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isBn ? bulletPointsBn[i] : bulletPointsEn[i],
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
