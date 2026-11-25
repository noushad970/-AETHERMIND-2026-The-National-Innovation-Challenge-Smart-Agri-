import 'package:flutter/material.dart';


import '../../features/auth/presentation/screens/login_screen.dart';

import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/onboarding/presentation/screens/app_tutorial_screen.dart';
import '../widgets/build_preview_screen.dart';
import 'app_routes.dart';

/// Generates [MaterialPageRoute]s for all named routes in [AppRoutes].
class AppRouter {
  AppRouter._();

  static Route<dynamic>? generate(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const BuildPreviewScreen());
      case AppRoutes.onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case AppRoutes.appTutorial:
        return MaterialPageRoute(builder: (_) => const AppTutorialScreen());
      case AppRoutes.login:
      case AppRoutes.register:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      default:
        return _unknownRoute(settings.name);
    }
  }

  static Route<dynamic> _unknownRoute(String? name) => MaterialPageRoute(
    builder: (_) =>
        Scaffold(body: Center(child: Text('Route not found: $name'))),
  );
}
