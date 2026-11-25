import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/services/notification_service.dart';

/// First-time Onboarding flow:
/// 1. Language Selection (Bangla / English)
/// 2. Location Permission with clear farmer benefits
/// 3. Professional Interactive App Tutorial & Guidelines
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isRequestingLocation = false;

  final int _totalPages = 7; // 0: Lang, 1: Location, 2..6: Tutorial Steps

  Future<void> _requestLocation() async {
    setState(() => _isRequestingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      await NotificationService.instance.requestNotificationPermission();
    } catch (_) {}
    if (mounted) {
      setState(() => _isRequestingLocation = false);
      _nextPage();
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.hasCompletedOnboardingKey, true);
    } catch (_) {}

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.splash);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBn = context.isBn;
    final isLastPage = _currentPage == _totalPages - 1;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentPage > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              )
            : null,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/app_logo.png',
              width: 28,
              height: 28,
              errorBuilder: (_, _, _) => const Icon(
                Icons.agriculture,
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              AppStrings.appName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppTheme.primaryGreen,
              ),
            ),
          ],
        ),
        actions: [
          // Quick Skip to Homepage button available on all tutorial pages
          if (_currentPage >= 2)
            TextButton.icon(
              onPressed: _finishOnboarding,
              icon: const Icon(Icons.home_outlined, size: 18, color: AppTheme.primaryGreen),
              label: Text(
                isBn ? 'হোমপেজে যান' : 'Go to Home',
                style: const TextStyle(
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Page Content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: _currentPage <= 1
                    ? const NeverScrollableScrollPhysics()
                    : const BouncingScrollPhysics(),
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                children: [
                  _buildLanguagePage(context),
                  _buildLocationPage(context),
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

            // Bottom Navigation & Progress Indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    offset: const Offset(0, -3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Page Indicators
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

                  // Action Buttons
                  if (_currentPage == 0) ...[
                    // Language page Next button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _nextPage,
                        child: Text(
                          isBn ? 'পরবর্তী (Next)' : 'Continue',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ] else if (_currentPage == 1) ...[
                    // Location Permission Page buttons
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isRequestingLocation ? null : _requestLocation,
                        icon: _isRequestingLocation
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.my_location),
                        label: Text(
                          isBn
                              ? 'লোকেশন অনুমতি দিন ও শুরু করুন'
                              : 'Allow Location & Continue',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _nextPage,
                      child: Text(
                        isBn ? 'এখন নয়, পরে অনুমতি দেব' : 'Skip for now',
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                  ] else if (isLastPage) ...[
                    // Final Tutorial Page: Prominent Complete Tutorial & Go to Homepage Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _finishOnboarding,
                        icon: const Icon(Icons.check_circle_outline, size: 22),
                        label: Text(
                          isBn
                              ? 'টিউটোরিয়াল সম্পন্ন করুন ও হোমপেজে যান'
                              : 'Complete Tutorial & Go to Home',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Ongoing Tutorial pages
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryGreen,
                                foregroundColor: Colors.white,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _nextPage,
                              icon: const Icon(Icons.arrow_forward),
                              label: Text(
                                isBn ? 'পরবর্তী ধাপ' : 'Next Step',
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Step 1: Language Selection Page ---
  Widget _buildLanguagePage(BuildContext context) {
    final localeProv = context.watch<LocaleProvider>();
    final isBn = localeProv.isBangla;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.translate,
              size: 48,
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'ভাষা নির্বাচন করুন\nSelect Your Language',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'অ্যাপের সকল তথ্য ও পরামর্শ আপনার পছন্দের ভাষায় দেখতে পারবেন',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),

          // Bangla Option Card
          InkWell(
            onTap: () => localeProv.setLanguage(AppLanguage.bangla),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isBn
                    ? AppTheme.primaryGreen.withValues(alpha: 0.08)
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isBn ? AppTheme.primaryGreen : AppTheme.divider,
                  width: isBn ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  const Text('🌾', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'বাংলা',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'বাংলাদেশের কৃষকদের জন্য সম্পূর্ণ বাংলায়',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isBn)
                    const Icon(
                      Icons.check_circle,
                      color: AppTheme.primaryGreen,
                      size: 24,
                    )
                  else
                    const Icon(
                      Icons.radio_button_off,
                      color: AppTheme.divider,
                      size: 24,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // English Option Card
          InkWell(
            onTap: () => localeProv.setLanguage(AppLanguage.english),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: !isBn
                    ? AppTheme.primaryGreen.withValues(alpha: 0.08)
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: !isBn ? AppTheme.primaryGreen : AppTheme.divider,
                  width: !isBn ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  const Text('🌿', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'English',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'All features in international English',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isBn)
                    const Icon(
                      Icons.check_circle,
                      color: AppTheme.primaryGreen,
                      size: 24,
                    )
                  else
                    const Icon(
                      Icons.radio_button_off,
                      color: AppTheme.divider,
                      size: 24,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Step 2: Location Permission Page ---
  Widget _buildLocationPage(BuildContext context) {
    final isBn = context.isBn;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.skyBlue.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_on,
              size: 56,
              color: AppTheme.skyBlue,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isBn ? 'আপনার এলাকার লোকেশন দিন' : 'Enable Device Location',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isBn
                ? 'সঠিক স্থানীয় আবহাওয়ার পূর্বাভাস, সেচের হিসাব ও নিকটস্থ কৃষি কর্মকর্তাদের তালিকা পেতে লোকেশন অনুমতি প্রয়োজন।'
                : 'Required to deliver accurate hyperlocal weather forecasts, soil moisture advisory, and your district extension officer directory.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),

          _buildBenefitItem(
            icon: Icons.cloud_outlined,
            color: AppTheme.skyBlue,
            titleBn: 'স্থানীয় আবহাওয়া ও ঝড় সতর্কবার্তা',
            titleEn: 'Hyperlocal Weather & Storm Alerts',
            subtitleBn: 'আপনার ইউনিয়নের রিয়েল-টাইম বৃষ্টি ও বাতাসের গতিবেগ',
            subtitleEn: 'Live Open-Meteo forecasts for your coordinates',
            isBn: isBn,
          ),
          const SizedBox(height: 14),
          _buildBenefitItem(
            icon: Icons.water_drop_outlined,
            color: AppTheme.primaryGreen,
            titleBn: 'স্মার্ট সেচ নির্ধারণ',
            titleEn: 'Smart Irrigation Calculations',
            subtitleBn: 'মাটি ও তাপমাত্রার ভিত্তিতে জমিতে পানির সঠিক পরিমাণ',
            subtitleEn: 'Calculate water requirements based on local heat & rain',
            isBn: isBn,
          ),
          const SizedBox(height: 14),
          _buildBenefitItem(
            icon: Icons.support_agent,
            color: AppTheme.accentAmber,
            titleBn: 'নিকটস্থ উপজেলা কৃষি কর্মকর্তা',
            titleEn: 'Local Upazila Agricultural Officers',
            subtitleBn: '৬৪ জেলার সংশ্লিষ্ট কর্মকর্তাদের সাথে সরাসরি যোগাযোগ',
            subtitleEn: 'Instant contact access to officers in your district',
            isBn: isBn,
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required Color color,
    required String titleBn,
    required String titleEn,
    required String subtitleBn,
    required String subtitleEn,
    required bool isBn,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isBn ? titleBn : titleEn,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isBn ? subtitleBn : subtitleEn,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Step 3..7: Tutorial Slides ---
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
          // Header Tag
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

          // Illustration Icon Avatar
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

          // Title
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

          // Description
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

          // Key Highlights Card
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
                  padding: EdgeInsets.only(bottom: i < bulletPointsBn.length - 1 ? 10 : 0),
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
