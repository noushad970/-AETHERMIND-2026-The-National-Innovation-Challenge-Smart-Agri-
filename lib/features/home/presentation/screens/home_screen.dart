import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/providers/animation_mode_provider.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/agri_animated_card.dart';
import '../../../../core/widgets/agri_atmospheric_background.dart';
import '../../../../core/widgets/agri_section_live_animation.dart';
import '../../../../core/widgets/animation_mode_chooser.dart';
import '../../../../core/widgets/loop_clock.dart';
import '../../../../core/widgets/header_action_bar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../crop_tracker/data/crop_summary_provider.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';
import '../../../weather/presentation/providers/weather_provider.dart';
import '../../../../data/models/crop.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _chooserHandled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeAskAnimationMode();
  }

  /// On the very first visit to the home screen after login, ask whether the
  /// user wants the animated or the static (low-end friendly) interface.
  /// Runs once per screen instance, and never again once a choice is saved.
  void _maybeAskAnimationMode() {
    if (_chooserHandled) return;
    final mode = Provider.of<AnimationModeProvider>(context);
    if (!mode.isLoaded) return; // wait for the saved preference to load
    _chooserHandled = true;
    if (mode.hasChosen) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showAnimationModeChooser(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final crops = context.watch<CropSummaryProvider>();
    final weather = context.watch<WeatherProvider>();
    final isBn = context.isBn;

    final greeting = _greetingFor(context, DateTime.now().hour);
    final displayName = auth.user?.displayName?.trim().isNotEmpty == true
        ? auth.user!.displayName!
        : (auth.user?.email?.split('@').first ??
            context.tr(AppStrings.farmer, AppStrings.farmerBn));

    final weatherData = weather.data;
    final tempStr = weatherData != null
        ? '${weatherData.temperatureC.toStringAsFixed(0)}°C'
        : '--°C';
    final condStr = weatherData != null
        ? (isBn ? weatherData.conditionLabelBn : weatherData.conditionLabel)
        : (isBn ? 'আবহাওয়া দেখতে চাপুন' : 'Tap to check the weather');

    return Scaffold(
      body: AgriAnimationClockScope(
        child: AgriAtmosphericBackground(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                centerTitle: false,
                backgroundColor: AppTheme.primaryGreenDark,
                surfaceTintColor: Colors.transparent,
                shape: const Border(),
                titleSpacing: 16,
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/app_logo.png',
                        width: 28,
                        height: 28,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.agriculture, size: 24),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        context.tr(AppStrings.appName, AppStrings.appNameBn),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                actions: [
                  const HeaderActionBar(),
                  Consumer<NotificationProvider>(
                    builder: (context, notifProv, _) {
                      final unread = notifProv.unreadCount;
                      return IconButton(
                        tooltip: context.tr(
                          AppStrings.notifications,
                          AppStrings.notificationsBn,
                        ),
                        icon: Badge(
                          isLabelVisible: unread > 0,
                          label: Text('$unread'),
                          backgroundColor: AppTheme.danger,
                          child: const Icon(Icons.notifications_outlined),
                        ),
                        onPressed: () =>
                            Navigator.of(context).pushNamed(AppRoutes.notifications),
                      );
                    },
                  ),
                  IconButton(
                    tooltip: context.tr('Settings & Alarms', 'সেটিংস ও অ্যালার্ম'),
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () => Navigator.of(context).pushNamed(AppRoutes.settings),
                  ),
                  PopupMenuButton<_HomeMenuAction>(
                    tooltip: context.tr('Account', 'অ্যাকাউন্ট'),
                    icon: const Icon(Icons.account_circle_outlined),
                    onSelected: (action) async {
                      switch (action) {
                        case _HomeMenuAction.settings:
                          Navigator.of(context).pushNamed(AppRoutes.settings);
                          break;
                        case _HomeMenuAction.appTutorial:
                          Navigator.of(context).pushNamed(AppRoutes.appTutorial);
                          break;
                        case _HomeMenuAction.logout:
                          await context.read<AuthProvider>().signOut();
                          if (!context.mounted) return;
                          Navigator.of(
                            context,
                          ).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
                          break;
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: _HomeMenuAction.settings,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.settings,
                            color: Color(0xFF00695C),
                          ),
                          title: Text(
                            context.tr(
                              'Settings & Alarms',
                              'সেটিংস ও অ্যালার্ম কন্ট্রোল',
                            ),
                          ),
                        ),
                      ),
                      PopupMenuItem(
                        value: _HomeMenuAction.appTutorial,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.menu_book_outlined,
                            color: AppTheme.primaryGreen,
                          ),
                          title: Text(
                            context.tr(
                              'App Guide / Tutorial',
                              'অ্যাপ নির্দেশিকা ও টিউটোরিয়াল',
                            ),
                          ),
                        ),
                      ),
                      PopupMenuItem(
                        value: _HomeMenuAction.logout,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.logout),
                          title: Text(
                            context.tr(AppStrings.logout, AppStrings.logoutBn),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: _HomeHeader(
                  greeting: greeting,
                  displayName: displayName,
                  tempStr: tempStr,
                  condStr: condStr,
                  isBn: isBn,
                ),
              ),

              // The two AI tools farmers reach for most.
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: _FeatureGrid(section: _HomeSection.primary),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: _ActiveCropsCard(summary: crops),
                ),
              ),

              ..._section(
                context,
                title: context.tr('My Farm', 'আমার খামার'),
                icon: Icons.agriculture_rounded,
                section: _HomeSection.myFarm,
              ),
              ..._section(
                context,
                title: context.tr('Plan & Decide', 'পরিকল্পনা ও সিদ্ধান্ত'),
                icon: Icons.insights_rounded,
                section: _HomeSection.plan,
              ),
              ..._section(
                context,
                title: context.tr('Learn & Connect', 'শিখুন ও যোগাযোগ করুন'),
                icon: Icons.groups_rounded,
                section: _HomeSection.learn,
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 96),
                sliver: SliverToBoxAdapter(
                  child: _RecentCropsCard(summary: crops),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.addCrop),
        backgroundColor: AppTheme.accentAmber,
        foregroundColor: AppTheme.textPrimary,
        elevation: 3,
        icon: const Icon(Icons.add),
        label: Text(
          context.tr(AppStrings.addCrop, AppStrings.addCropBn),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  List<Widget> _section(
    BuildContext context, {
    required String title,
    required IconData icon,
    required _HomeSection section,
  }) {
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 10),
        sliver: SliverToBoxAdapter(
          child: Row(
            children: [
              Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: _FeatureGrid(section: section),
      ),
    ];
  }

  String _greetingFor(BuildContext context, int hour) {
    if (hour < 12) {
      return context.tr(AppStrings.goodMorning, AppStrings.goodMorningBn);
    }
    if (hour < 17) {
      return context.tr(AppStrings.goodAfternoon, AppStrings.goodAfternoonBn);
    }
    return context.tr(AppStrings.goodEvening, AppStrings.goodEveningBn);
  }
}

/// Curved header that continues the app bar: greeting, season and the two
/// shortcuts (weather and irrigation advice).
class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.greeting,
    required this.displayName,
    required this.tempStr,
    required this.condStr,
    required this.isBn,
  });

  final String greeting;
  final String displayName;
  final String tempStr;
  final String condStr;
  final bool isBn;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.primaryGreenDark, AppTheme.primaryGreen],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$greeting,',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 14,
            ),
          ),
          Text(
            displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.spa, color: AppTheme.sunYellow, size: 14),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  isBn ? 'আমন ও রবি মৌসুম' : 'Kharif-2 & Rabi Season',
                  style: const TextStyle(color: AppTheme.sunYellow, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _HeaderTile(
                    icon: Icons.wb_sunny_rounded,
                    title: tempStr,
                    subtitle: condStr,
                    onTap: () => Navigator.of(context)
                        .pushNamed(AppRoutes.weatherScreen),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _HeaderTile(
                    icon: Icons.water_drop,
                    title: isBn ? 'সেচ পরামর্শ' : 'Irrigation AI',
                    subtitle: isBn ? 'পানির হিসাব দেখুন' : 'Check water needs',
                    onTap: () => Navigator.of(context)
                        .pushNamed(AppRoutes.smartIrrigation),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderTile extends StatelessWidget {
  const _HeaderTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.sunYellow, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _HomeSection { primary, myFarm, plan, learn }

class _ActiveCropsCard extends StatelessWidget {
  const _ActiveCropsCard({required this.summary});
  final CropSummaryProvider summary;

  static const int _previewLimit = 3;

  @override
  Widget build(BuildContext context) {
    if (summary.isLoading) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    final total = summary.activeCropCount;
    final preview = summary.recent.take(_previewLimit).toList(growable: false);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryGreenLight, AppTheme.primaryGreen],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.eco, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$total',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                    ),
                    Text(
                      context.tr(
                        AppStrings.activeCrops,
                        AppStrings.activeCropsBn,
                      ),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.cropList),
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: Text(
                  context.tr(AppStrings.viewAll, AppStrings.viewAllBn),
                ),
              ),
            ],
          ),
          if (preview.isEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.add_circle_outline,
                    color: AppTheme.primaryGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.tr(
                        AppStrings.addYourFirstCrop,
                        AppStrings.addYourFirstCropBn,
                      ),
                      style: const TextStyle(
                        color: AppTheme.primaryGreen,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            for (var i = 0; i < preview.length; i++) ...[
              _ActiveCropDetailTile(crop: preview[i]),
              if (i != preview.length - 1) const Divider(height: 1),
            ],
          ],
        ],
      ),
    );
  }
}

class _ActiveCropDetailTile extends StatelessWidget {
  const _ActiveCropDetailTile({required this.crop});
  final Crop crop;

  @override
  Widget build(BuildContext context) {
    final progress = (crop.progress * 100).toStringAsFixed(0);
    final harvestDate = _formatDate(crop.estimatedHarvestDate);

    return InkWell(
      onTap: () => Navigator.of(
        context,
      ).pushNamed(AppRoutes.cropLiveTrack, arguments: crop.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    crop.variety.isNotEmpty
                        ? '${crop.cropType} (${crop.variety})'
                        : crop.cropType,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  '$progress%',
                  style: const TextStyle(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: crop.progress,
                minHeight: 6,
                backgroundColor:
                    AppTheme.primaryGreenLight.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryGreen,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '🌱 ${crop.currentGrowthStage}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  '🌾 ${context.tr("Harvest", "ফসল তোলা")}: $harvestDate',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day}/${d.month}/${d.year}';
  }
}

/// A lazy grid for one home section, so only cards on (or near) the screen are
/// built and animated.
class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid({required this.section});

  final _HomeSection section;

  List<Widget> _cards(BuildContext context, bool isBn) {
    switch (section) {
      case _HomeSection.primary:
        return [
          AgriAnimatedCard(
            title: context.tr(AppStrings.aiDiseaseDetect, AppStrings.aiDiseaseDetectBn),
            subtitle: isBn
                ? 'ফসলের রোগ নির্ণয় ও তাৎক্ষণিক সমাধান'
                : 'Detect crop diseases & get instant solutions',
            icon: Icons.qr_code_scanner_rounded,
            imageBgUrl: 'https://images.unsplash.com/photo-1530836369250-ef72a3f5cda8?auto=format&fit=crop&w=400&q=75',
            animationType: AgriCardAnimationType.diseaseScan,
            gradient: const LinearGradient(
              colors: [Color(0xFF1B7A5C), Color(0xFF00796B)],
            ),
            badgeText: 'AI Doctor',
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.diseaseDetect),
          ),
          AgriAnimatedCard(
            title: context.tr(AppStrings.aiChatbot, AppStrings.aiChatbotBn),
            subtitle: isBn
                ? '২৪/৭ কৃষি এআই বিশেষজ্ঞের পরামর্শ'
                : '24/7 AI farming advisor & advice',
            icon: Icons.psychology_outlined,
            imageBgUrl: 'https://images.unsplash.com/photo-1581091226825-a6a2a5aee158?auto=format&fit=crop&w=400&q=75',
            animationType: AgriCardAnimationType.aiNeural,
            gradient: const LinearGradient(
              colors: [Color(0xFF0288D1), Color(0xFF0097A7)],
            ),
            badgeText: 'Gemini AI',
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.chatbot),
          ),
        ];
      case _HomeSection.myFarm:
        return [
          AgriAnimatedCard(
            title: context.tr(AppStrings.myCrops, AppStrings.myCropsBn),
            subtitle: isBn
                ? 'ফসলের বৃদ্ধি ও ফসল তোলার সময় ট্র্যাক'
                : 'Track crop growth & harvest schedule',
            icon: Icons.grass_rounded,
            imageBgUrl: 'https://images.unsplash.com/photo-1500937386664-56d1dfef3854?auto=format&fit=crop&w=400&q=75',
            animationType: AgriCardAnimationType.cropGrowth,
            gradient: const LinearGradient(
              colors: [Color(0xFF0F5C4A), Color(0xFF388E3C)],
            ),
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.cropList),
          ),
          AgriAnimatedCard(
            title: context.tr(AppStrings.livestock, AppStrings.livestockBn),
            subtitle: isBn
                ? 'গবাদিপশুর স্বাস্থ্য সেবা ও সুষম খাবার'
                : 'Cattle health, feed & milk records',
            icon: Icons.pets_rounded,
            imageBgUrl: 'https://images.unsplash.com/photo-1546445317-29f4545e9d53?auto=format&fit=crop&w=400&q=75',
            animationType: AgriCardAnimationType.livestockHeartbeat,
            gradient: const LinearGradient(
              colors: [Color(0xFF4E342E), Color(0xFF6D4C41)],
            ),
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.livestockList),
          ),
          AgriAnimatedCard(
            title: context.tr(AppStrings.fishTracker, AppStrings.fishTrackerBn),
            subtitle: isBn
                ? '২০টি দেশীয় মাছের লাইভ বৃদ্ধি, খাবার ও অক্সিজেন'
                : 'Top 20 BD fishes live tracking, feed & aeration',
            icon: Icons.set_meal_rounded,
            imageBgUrl: 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?auto=format&fit=crop&w=400&q=75',
            animationType: AgriCardAnimationType.irrigationRipples,
            gradient: const LinearGradient(
              colors: [Color(0xFF00695C), Color(0xFF00897B)],
            ),
            badgeText: 'Fish Live',
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.fishList),
          ),
          AgriAnimatedCard(
            title: context.tr(AppStrings.farmRecords, AppStrings.farmRecordsBn),
            subtitle: isBn
                ? 'সার, বীজ ও শ্রমের খরচ এবং আয়ের খাতা'
                : 'Track seeds, fertilizer costs & income',
            icon: Icons.account_balance_wallet_outlined,
            imageBgUrl: 'https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?auto=format&fit=crop&w=400&q=75',
            animationType: AgriCardAnimationType.recordsLedger,
            gradient: const LinearGradient(
              colors: [Color(0xFF37474F), Color(0xFF546E7A)],
            ),
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.farmRecords),
          ),
        ];
      case _HomeSection.plan:
        return [
          AgriAnimatedCard(
            title: context.tr(AppStrings.weather, AppStrings.weatherBn),
            subtitle: isBn
                ? '৭ দিনের পূর্বাভাস ও বৃষ্টির সতর্কতা'
                : '7-day forecast & farm rain alerts',
            icon: Icons.cloud_sync_outlined,
            imageBgUrl: 'https://images.unsplash.com/photo-1534088568595-a066f410bcda?auto=format&fit=crop&w=400&q=75',
            animationType: AgriCardAnimationType.weatherAtmosphere,
            gradient: const LinearGradient(
              colors: [Color(0xFF0277BD), Color(0xFF00838F)],
            ),
            badgeText: 'Live',
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.weatherScreen),
          ),
          AgriAnimatedCard(
            title: context.tr(AppStrings.smartIrrigation, AppStrings.smartIrrigationBn),
            subtitle: isBn
                ? 'মাটির আর্দ্রতা মেপে সেচ ও পানির হিসাব'
                : 'Soil moisture test & pump water needs',
            icon: Icons.water_drop_outlined,
            imageBgUrl: 'https://images.unsplash.com/photo-1563514227147-6d2ff665a6a0?auto=format&fit=crop&w=400&q=75',
            animationType: AgriCardAnimationType.irrigationRipples,
            gradient: const LinearGradient(
              colors: [Color(0xFF00695C), Color(0xFF00897B)],
            ),
            badgeText: 'Smart IoT',
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.smartIrrigation),
          ),
          AgriAnimatedCard(
            title: context.tr(AppStrings.marketPrices, AppStrings.marketPricesBn),
            subtitle: isBn
                ? '৫০+ পণ্যের পাইকারি ও খুচরা বাজার দর'
                : 'Daily rates for 50+ produce items',
            icon: Icons.storefront_rounded,
            imageBgUrl: 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=400&q=75',
            animationType: AgriCardAnimationType.marketTrends,
            gradient: const LinearGradient(
              colors: [Color(0xFFE65100), Color(0xFFF57C00)],
            ),
            badgeText: 'AI Rates',
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.marketPrices),
          ),
          AgriAnimatedCard(
            title: context.tr(AppStrings.yieldForecaster, AppStrings.yieldForecasterBn),
            subtitle: isBn
                ? 'সম্ভাব্য মোট উৎপাদন ও মুনাফার পূর্বাভাস'
                : 'Estimate harvest yield & net profit',
            icon: Icons.insights_rounded,
            imageBgUrl: 'https://images.unsplash.com/photo-1574943320219-553eb213f72d?auto=format&fit=crop&w=400&q=75',
            animationType: AgriCardAnimationType.yieldForecast,
            gradient: const LinearGradient(
              colors: [Color(0xFFF57F17), Color(0xFFFFA000)],
            ),
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.yieldForecaster),
          ),
        ];
      case _HomeSection.learn:
        return [
          AgriAnimatedCard(
            title: context.tr(AppStrings.cropDirectory, AppStrings.cropDirectoryBn),
            subtitle: isBn
                ? '৬৪+ ফসলের পূর্ণাঙ্গ চাষাবাদ গাইড'
                : 'Cultivation guides for 64+ crops',
            icon: Icons.local_library_outlined,
            imageBgUrl: 'https://images.unsplash.com/photo-1523348837708-15d4a09cfac2?auto=format&fit=crop&w=400&q=75',
            animationType: AgriCardAnimationType.libraryBook,
            gradient: const LinearGradient(
              colors: [Color(0xFF5D4037), Color(0xFF795548)],
            ),
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.cropLibrary),
          ),
          AgriAnimatedCard(
            title: context.tr(AppStrings.communityFeed, AppStrings.communityFeedBn),
            subtitle: isBn
                ? 'কৃষকদের ছবি, অভিজ্ঞতা ও আলোচনা'
                : 'Share farm photos & farmer QA',
            icon: Icons.forum_rounded,
            imageBgUrl: 'https://images.unsplash.com/photo-1595974482597-4b8da8879bc5?auto=format&fit=crop&w=400&q=75',
            animationType: AgriCardAnimationType.communityPulse,
            gradient: const LinearGradient(
              colors: [Color(0xFF33691E), Color(0xFF558B2F)],
            ),
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.communityFeed),
          ),
          AgriAnimatedCard(
            title: context.tr(AppStrings.krishiHelpline, AppStrings.krishiHelplineBn),
            subtitle: isBn
                ? '১৬১২৩ হেল্পলাইন ও কর্মকর্তার নম্বর'
                : '16123 hotline & officer directory',
            icon: Icons.phone_in_talk_rounded,
            imageBgUrl: 'https://images.unsplash.com/photo-1577563908411-5077b6dc7624?auto=format&fit=crop&w=400&q=75',
            animationType: AgriCardAnimationType.helplineSignal,
            gradient: const LinearGradient(
              colors: [Color(0xFF004D40), Color(0xFF00796B)],
            ),
            badgeText: '16123',
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.krishiHelpline),
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final cards = _cards(context, context.isBn);

    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.crossAxisExtent;
        final int crossAxisCount = width > 600 ? 3 : 2;
        final double childAspectRatio = width < 360
            ? 1.02
            : (width > 600 ? 1.22 : 1.10);

        return SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: childAspectRatio,
          ),
          delegate: SliverChildBuilderDelegate(
            (_, i) => cards[i],
            childCount: cards.length,
          ),
        );
      },
    );
  }
}

class _RecentCropsCard extends StatelessWidget {
  const _RecentCropsCard({required this.summary});
  final CropSummaryProvider summary;

  @override
  Widget build(BuildContext context) {
    final recent = summary.recent;
    if (recent.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('Recent Fields Under Cultivation', 'সম্প্রতি চাষকৃত ফসলের জমি'),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          for (final c in recent) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreenLight.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.eco, color: AppTheme.primaryGreen, size: 20),
              ),
              title: Text(
                c.variety.isNotEmpty
                    ? '${c.cropType} (${c.variety})'
                    : c.cropType,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${c.currentGrowthStage} • ${c.landAreaDecimal.toStringAsFixed(1)} ${context.tr("dec", "শতক")}',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: Text(
                '${(c.progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
              ),
              onTap: () => Navigator.of(
                context,
              ).pushNamed(AppRoutes.cropLiveTrack, arguments: c.id),
            ),
            const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

enum _HomeMenuAction { settings, appTutorial, logout }
