import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/locale_provider.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/screens/splash_screen.dart';
import '../widgets/landing_view.dart';

/// [LandingView] connected to the app's providers and navigator.
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

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
