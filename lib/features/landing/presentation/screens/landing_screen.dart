import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/screens/splash_screen.dart';
import '../widgets/landing_view.dart';

/// [LandingView] connected to the app's providers and navigator.
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  /// Opens the Android app's download page in a new tab.
  Future<void> _downloadApp(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final isBn = context.read<LocaleProvider>().isBangla;

    var opened = false;
    try {
      opened = await launchUrl(
        Uri.parse(AppConfig.androidApkUrl),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('Could not open the app download: $e');
    }
    if (opened) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          isBn
              ? 'ডাউনলোড পেজটি খোলা যায়নি। আবার চেষ্টা করুন।'
              : 'Could not open the download page. Please try again.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSignedIn = context.select<AuthProvider, bool>(
      (auth) => auth.isAuthenticated,
    );

    return LandingView(
      isBn: context.isBn,
      isSignedIn: isSignedIn,
      onToggleLanguage: context.read<LocaleProvider>().toggleLanguage,
      // The start screen leads on to the welcome pages, login or home.
      onLogin: () =>
          Navigator.of(context).pushReplacementNamed(AppRoutes.appStart),
      onDownloadApp: () => _downloadApp(context),
      // The finished sunrise over the fields, held still.
      heroBackground: ClipRect(
        child: RepaintBoundary(
          child: CustomPaint(
            painter: AgriculturalDawnSunrisePainter(
              sunriseProgress: 1,
              loopProgress: 0.25,
            ),
          ),
        ),
      ),
    );
  }
}
