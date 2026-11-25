import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';

/// A titled row of feature cards on the desktop home page.
class DesktopFeatureSection {
  const DesktopFeatureSection({
    required this.title,
    required this.description,
    required this.cards,
  });

  final String title;
  final String description;
  final List<Widget> cards;
}

/// The home page for wide windows, laid out like a website landing page:
/// hero banner, quick figures, the farmer's fields, features and a footer.
///
/// It only draws what it is given, so it needs no providers.
class DesktopHomeView extends StatelessWidget {
  const DesktopHomeView({
    super.key,
    required this.isBn,
    required this.greeting,
    required this.displayName,
    required this.temperature,
    required this.condition,
    required this.activeCropCount,
    required this.heroBackground,
    required this.activeCrops,
    required this.sections,
    required this.onOpen,
    this.recentCrops,
  });

  static const double maxContentWidth = 1180;
  static const double _gap = 16;
  static const double _cardHeight = 190;

  final bool isBn;
  final String greeting;
  final String displayName;
  final String temperature;
  final String condition;

  /// Null while the crops are still loading.
  final int? activeCropCount;

  /// Artwork painted behind the hero banner.
  final Widget heroBackground;

  final Widget activeCrops;
  final Widget? recentCrops;
  final List<DesktopFeatureSection> sections;

  /// Opens the named route.
  final ValueChanged<String> onOpen;

  String _t(String en, String bn) => isBn ? bn : en;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.max(
          32.0,
          (constraints.maxWidth - maxContentWidth) / 2,
        );
        final width = constraints.maxWidth - side * 2;

        Widget block(Widget child, {double top = 24}) => SliverPadding(
          padding: EdgeInsets.fromLTRB(side, top, side, 0),
          sliver: SliverToBoxAdapter(child: child),
        );

        return CustomScrollView(
          slivers: [
            block(_hero(width)),
            block(_stats(context, width), top: _gap),
            block(_fields(width)),
            for (final section in sections) ...[
              block(
                _heading(context, section.title, section.description),
                top: 36,
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(side, _gap, side, 0),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _columns(section.cards.length, width),
                    crossAxisSpacing: _gap,
                    mainAxisSpacing: _gap,
                    mainAxisExtent: _cardHeight,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _HoverLift(child: section.cards[i]),
                    childCount: section.cards.length,
                  ),
                ),
              ),
            ],
            block(
              _heading(
                context,
                _t('How it works', 'যেভাবে কাজ করে'),
                _t(
                  'Three steps from your field to a better decision.',
                  'মাঠ থেকে সঠিক সিদ্ধান্তে পৌঁছানোর তিনটি ধাপ।',
                ),
              ),
              top: 40,
            ),
            block(_steps(context, width), top: _gap),
            SliverPadding(
              padding: const EdgeInsets.only(top: 40),
              sliver: SliverToBoxAdapter(child: _footer(side)),
            ),
          ],
        );
      },
    );
  }

  /// Four cards share a row only when there is room; otherwise they pair up.
  static int _columns(int count, double width) {
    if (count == 4) return width >= 900 ? 4 : 2;
    return count.clamp(1, 3);
  }

  Widget _hero(double width) {
    final sideBySide = width >= 860;
    final shortcuts = [
      _HeroTile(
        icon: Icons.wb_sunny_rounded,
        title: temperature,
        subtitle: condition,
        onTap: () => onOpen(AppRoutes.weatherScreen),
      ),
      _HeroTile(
        icon: Icons.water_drop,
        title: _t('Irrigation AI', 'সেচ পরামর্শ'),
        subtitle: _t('Check water needs', 'পানির হিসাব দেখুন'),
        onTap: () => onOpen(AppRoutes.smartIrrigation),
      ),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 380),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            Positioned.fill(child: heroBackground),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryGreenDark.withValues(alpha: 0.96),
                      AppTheme.primaryGreenDark.withValues(alpha: 0.82),
                      AppTheme.primaryGreenDark.withValues(
                        alpha: sideBySide ? 0.25 : 0.7,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: sideBySide
                    ? Row(
                        children: [
                          Expanded(child: _headline()),
                          const SizedBox(width: 32),
                          SizedBox(
                            width: 290,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                shortcuts[0],
                                const SizedBox(height: 12),
                                shortcuts[1],
                              ],
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _headline(),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(child: shortcuts[0]),
                              const SizedBox(width: 12),
                              Expanded(child: shortcuts[1]),
                            ],
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headline() {
    const buttonSize = Size(0, 50);
    const buttonPadding = EdgeInsets.symmetric(horizontal: 22);
    const buttonText = TextStyle(
      fontFamily: 'NotoSansBengali',
      fontWeight: FontWeight.bold,
      fontSize: 15,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.spa, color: AppTheme.sunYellow, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                _t('Kharif-2 & Rabi Season', 'আমন ও রবি মৌসুম'),
                style: const TextStyle(color: AppTheme.sunYellow, fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          '$greeting, $displayName',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.88),
            fontSize: 17,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _t(
            'Smarter farming for every field',
            'প্রতিটি জমির জন্য স্মার্ট চাষাবাদ',
          ),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 42,
            height: 1.2,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Text(
            _t(
              'Scan crop diseases, ask the AI advisor and plan irrigation, '
                  'weather and market decisions in one place.',
              'ফসলের রোগ শনাক্ত করুন, এআই পরামর্শ নিন এবং সেচ, আবহাওয়া ও '
                  'বাজার দর এক জায়গায় দেখুন।',
            ),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.accentAmber,
                foregroundColor: AppTheme.textPrimary,
                minimumSize: buttonSize,
                padding: buttonPadding,
                textStyle: buttonText,
              ),
              onPressed: () => onOpen(AppRoutes.diseaseDetect),
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
              label: Text(
                _t('Scan a crop disease', 'ফসলের রোগ স্ক্যান করুন'),
              ),
            ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white70, width: 1.5),
                minimumSize: buttonSize,
                padding: buttonPadding,
                textStyle: buttonText,
              ),
              onPressed: () => onOpen(AppRoutes.chatbot),
              icon: const Icon(Icons.psychology_outlined, size: 20),
              label: Text(_t('Ask the AI advisor', 'এআই পরামর্শ নিন')),
            ),
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                minimumSize: buttonSize,
                padding: buttonPadding,
                textStyle: buttonText,
              ),
              onPressed: () => onOpen(AppRoutes.addCrop),
              icon: const Icon(Icons.add, size: 20),
              label: Text(_t('Add a crop', 'ফসল যোগ করুন')),
            ),
          ],
        ),
      ],
    );
  }

  Widget _stats(BuildContext context, double width) {
    final stats = [
      (
        Icons.eco,
        activeCropCount?.toString() ?? '…',
        _t('Active crops', 'চলমান ফসল'),
        AppRoutes.cropList,
      ),
      (
        Icons.thermostat,
        temperature,
        _t('Temperature now', 'বর্তমান তাপমাত্রা'),
        AppRoutes.weatherScreen,
      ),
      (
        Icons.phone_in_talk_rounded,
        '16123',
        _t('Krishi helpline', 'কৃষি হেল্পলাইন'),
        AppRoutes.krishiHelpline,
      ),
      (
        Icons.local_library_outlined,
        _t('64+', '৬৪+'),
        _t('Crop guides', 'ফসল নির্দেশিকা'),
        AppRoutes.cropLibrary,
      ),
    ];
    final perRow = width >= 880 ? 4 : 2;
    final itemWidth = (width - _gap * (perRow - 1)) / perRow;
    final theme = Theme.of(context);

    return Wrap(
      spacing: _gap,
      runSpacing: _gap,
      children: [
        for (final (icon, value, label, route) in stats)
          SizedBox(
            width: itemWidth.floorToDouble(),
            child: Material(
              color: theme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: theme.dividerColor),
              ),
              child: InkWell(
                key: ValueKey('stat:$route'),
                borderRadius: BorderRadius.circular(18),
                onTap: () => onOpen(route),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppTheme.primaryGreenLight.withValues(
                          alpha: 0.16,
                        ),
                        child: Icon(icon, color: theme.colorScheme.primary),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _fields(double width) {
    final recent = recentCrops;
    if (recent == null) return activeCrops;
    if (width < 900) {
      return Column(
        children: [activeCrops, const SizedBox(height: _gap), recent],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: activeCrops),
        const SizedBox(width: _gap),
        Expanded(child: recent),
      ],
    );
  }

  Widget _heading(BuildContext context, String title, String description) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(description, style: theme.textTheme.bodyMedium),
      ],
    );
  }

  Widget _steps(BuildContext context, double width) {
    final steps = [
      (
        _t('Add your farm', 'আপনার খামার যোগ করুন'),
        _t(
          'Register crops, cattle and fish ponds to track growth and schedules.',
          'ফসল, গবাদিপশু ও পুকুর যোগ করে বৃদ্ধি ও সময়সূচি দেখুন।',
        ),
      ),
      (
        _t('Ask the AI', 'এআই-কে জিজ্ঞাসা করুন'),
        _t(
          'Upload a leaf photo or ask a question in Bangla or English.',
          'পাতার ছবি দিন অথবা বাংলা বা ইংরেজিতে প্রশ্ন করুন।',
        ),
      ),
      (
        _t('Act on time', 'সময়মতো ব্যবস্থা নিন'),
        _t(
          'Check weather, irrigation advice and market prices before deciding.',
          'সিদ্ধান্তের আগে আবহাওয়া, সেচ পরামর্শ ও বাজার দর দেখুন।',
        ),
      ),
    ];
    final theme = Theme.of(context);
    final cards = [
      for (final (index, (title, body)) in steps.indexed)
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                child: Text('${index + 1}'),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(body, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
    ];

    if (width < 760) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final card in cards) ...[card, const SizedBox(height: _gap)],
        ],
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, card) in cards.indexed) ...[
            if (index > 0) const SizedBox(width: _gap),
            Expanded(child: card),
          ],
        ],
      ),
    );
  }

  Widget _footer(double side) {
    Widget links(String title, List<(String, String)> items) => SizedBox(
      width: 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.sunYellow,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          for (final (label, route) in items)
            TextButton(
              key: ValueKey('footer:$route'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 36),
              ),
              onPressed: () => onOpen(route),
              child: Text(label),
            ),
        ],
      ),
    );

    return ColoredBox(
      color: AppTheme.primaryGreenDark,
      child: Padding(
        padding: EdgeInsets.fromLTRB(side, 32, side, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 48,
              runSpacing: 24,
              children: [
                SizedBox(
                  width: 300,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Smart Agri BD',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _t(
                          'An AI farm assistant made for the farmers of '
                              'Bangladesh.',
                          'বাংলাদেশের কৃষকদের জন্য তৈরি এআই কৃষি সহকারী।',
                        ),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                links(_t('Explore', 'ঘুরে দেখুন'), [
                  (_t('Weather', 'আবহাওয়া'), AppRoutes.weatherScreen),
                  (_t('Market prices', 'বাজার দর'), AppRoutes.marketPrices),
                  (_t('Community', 'কৃষক ফিড'), AppRoutes.communityFeed),
                ]),
                links(_t('Support', 'সহায়তা'), [
                  (_t('Helpline', 'হেল্পলাইন'), AppRoutes.krishiHelpline),
                  (_t('App guide', 'অ্যাপ নির্দেশিকা'), AppRoutes.appTutorial),
                  (_t('Settings', 'সেটিংস'), AppRoutes.settings),
                ]),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Weather and irrigation shortcuts on the hero banner.
class _HeroTile extends StatelessWidget {
  const _HeroTile({
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
      color: Colors.black.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.sunYellow, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }
}

/// Raises a card slightly under the mouse pointer.
class _HoverLift extends StatefulWidget {
  const _HoverLift({required this.child});

  final Widget child;

  @override
  State<_HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<_HoverLift> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedSlide(
        offset: Offset(0, _hovered ? -0.025 : 0),
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
