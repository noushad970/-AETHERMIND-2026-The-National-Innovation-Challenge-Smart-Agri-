import 'package:flutter/material.dart';


import '../widgets/build_preview_screen.dart';
import 'app_routes.dart';

/// Generates [MaterialPageRoute]s for all named routes in [AppRoutes].
class AppRouter {
  AppRouter._();

  static Route<dynamic>? generate(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const BuildPreviewScreen());
      default:
        return _unknownRoute(settings.name);
    }
  }

  static Route<dynamic> _unknownRoute(String? name) => MaterialPageRoute(
    builder: (_) =>
        Scaffold(body: Center(child: Text('Route not found: $name'))),
  );
}
