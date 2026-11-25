import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import 'desktop_scope.dart';

/// How a page uses the space on a desktop window.
class DesktopPageStyle {
  const DesktopPageStyle(this.maxWidth, {this.brandPanel = false});

  /// The widest the page content may grow.
  final double maxWidth;

  /// Shows a welcome panel to the left of the page.
  final bool brandPanel;

  static const DesktopPageStyle full = DesktopPageStyle(double.infinity);
  static const DesktopPageStyle wide = DesktopPageStyle(1280);
  static const DesktopPageStyle reading = DesktopPageStyle(920);
  static const DesktopPageStyle form = DesktopPageStyle(760);
  static const DesktopPageStyle auth = DesktopPageStyle(560, brandPanel: true);

  static DesktopPageStyle forRoute(String? route) {
    switch (route) {
      case AppRoutes.splash:
      case AppRoutes.appStart:
      case AppRoutes.home:
        return full;
      case AppRoutes.login:
      case AppRoutes.register:
        return auth;
      case AppRoutes.onboarding:
      case AppRoutes.appTutorial:
      case AppRoutes.addCrop:
      case AppRoutes.addLivestock:
      case AppRoutes.addFish:
      case AppRoutes.addExpense:
        return form;
      case AppRoutes.chatbot:
      case AppRoutes.communityFeed:
      case AppRoutes.notifications:
      case AppRoutes.expenseList:
      case AppRoutes.cropLiveTrack:
      case AppRoutes.livestockLiveTrack:
      case AppRoutes.fishLiveTrack:
        return reading;
      default:
        return wide;
    }
  }
}

/// Centers a page on wide windows. On smaller windows the page is unchanged.
class DesktopPageFrame extends StatelessWidget {
  const DesktopPageFrame({
    super.key,
    required this.style,
    required this.child,
  });

  final DesktopPageStyle style;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDesktop = DesktopScope.of(context);
    final theme = Theme.of(context);
    final backdrop = Color.alphaBlend(
      AppTheme.primaryGreen.withValues(alpha: 0.08),
      theme.scaffoldBackgroundColor,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final total = constraints.maxWidth;
        final showPanel = isDesktop && style.brandPanel;
        final panelWidth = showPanel && total > style.maxWidth
            ? total - style.maxWidth
            : 0.0;
        final available = total - panelWidth;
        final width = isDesktop && available > style.maxWidth
            ? style.maxWidth
            : available;
        final media = MediaQuery.of(context);

        return ColoredBox(
          color: isDesktop ? backdrop : Colors.transparent,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: panelWidth,
                child: panelWidth > 0 ? const _BrandPanel() : null,
              ),
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: width,
                    height: constraints.maxHeight,
                    child: MediaQuery(
                      data: media.copyWith(
                        size: Size(width, media.size.height),
                      ),
                      child: child,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  static const List<(IconData, String, String)> _points = [
    (
      Icons.qr_code_scanner_rounded,
      'AI crop disease detection',
      'এআই দিয়ে ফসলের রোগ নির্ণয়',
    ),
    (
      Icons.psychology_outlined,
      'Farming advice in Bangla and English',
      'বাংলা ও ইংরেজিতে কৃষি পরামর্শ',
    ),
    (
      Icons.cloud_outlined,
      'Weather, irrigation and market prices',
      'আবহাওয়া, সেচ ও বাজার দর',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.primaryGreenDark,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.asset(
                    'assets/app_logo.png',
                    width: 72,
                    height: 72,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.agriculture,
                      color: Colors.white,
                      size: 64,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Smart Agri BD',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'স্মার্ট চাষাবাদ, সমৃদ্ধ কৃষক',
                  style: TextStyle(color: AppTheme.sunYellow, fontSize: 18),
                ),
                const SizedBox(height: 32),
                for (final (icon, label, labelBn) in _points)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      children: [
                        Icon(icon, color: AppTheme.sunYellow),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                labelBn,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
