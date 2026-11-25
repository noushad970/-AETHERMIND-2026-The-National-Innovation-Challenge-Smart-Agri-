import 'package:ai_agri_assistant/core/layout/app_navigation.dart';
import 'package:ai_agri_assistant/core/routes/app_router.dart';
import 'package:ai_agri_assistant/core/routes/app_routes.dart';
import 'package:ai_agri_assistant/core/theme/app_theme.dart';
import 'package:ai_agri_assistant/features/landing/presentation/widgets/landing_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void _setWindow(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// The landing page with a working language switch.
Widget _landing({
  bool isSignedIn = false,
  VoidCallback? onLogin,
  ThemeData? theme,
}) {
  var isBn = false;
  return MaterialApp(
    theme: theme ?? AppTheme.lightTheme(),
    home: StatefulBuilder(
      builder: (_, setState) => LandingView(
        isBn: isBn,
        isSignedIn: isSignedIn,
        onToggleLanguage: () => setState(() => isBn = !isBn),
        onLogin: onLogin ?? () {},
        heroBackground: const ColoredBox(color: Colors.green),
      ),
    ),
  );
}

const _headline = 'Smarter farming for every field';
const _headlineBn = 'প্রতিটি জমির জন্য স্মার্ট চাষাবাদ';

void main() {
  for (final size in const [
    Size(360, 740),
    Size(390, 844),
    Size(700, 900),
    Size(1024, 768),
    Size(1920, 1000),
  ]) {
    testWidgets('lays out without overflow at ${size.width}', (tester) async {
      _setWindow(tester, size);
      await tester.pumpWidget(_landing());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey('landing-language')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('works with the dark theme', (tester) async {
    _setWindow(tester, const Size(1280, 800));
    await tester.pumpWidget(_landing(theme: AppTheme.darkTheme()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('switches between English and Bangla', (tester) async {
    _setWindow(tester, const Size(1280, 800));
    await tester.pumpWidget(_landing());

    expect(find.text(_headline), findsOneWidget);
    expect(find.text('বাংলা'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('landing-language')));
    await tester.pumpAndSettle();

    expect(find.text(_headline), findsNothing);
    expect(find.text(_headlineBn), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('লগইন'), findsNWidgets(3));
  });

  testWidgets('every login button opens the app', (tester) async {
    _setWindow(tester, const Size(1280, 800));
    var logins = 0;
    await tester.pumpWidget(_landing(onLogin: () => logins++));

    for (final key in [
      'landing-nav-login',
      'landing-hero-login',
      'landing-cta-login',
    ]) {
      final button = find.byKey(ValueKey(key));
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
    }
    expect(logins, 3);
  });

  testWidgets('the features link scrolls to the features', (tester) async {
    _setWindow(tester, const Size(1280, 700));
    await tester.pumpWidget(_landing());
    final heading = find.text('Everything your farm needs');
    final before = tester.getTopLeft(heading).dy;

    await tester.tap(find.byKey(const ValueKey('landing-nav-features')));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(heading).dy, lessThan(before));
  });

  testWidgets('phones hide the section links', (tester) async {
    _setWindow(tester, const Size(390, 844));
    await tester.pumpWidget(_landing());

    expect(find.byKey(const ValueKey('landing-nav-features')), findsNothing);
    expect(find.byKey(const ValueKey('landing-nav-login')), findsOneWidget);
  });

  testWidgets('signed-in visitors are offered the dashboard', (tester) async {
    _setWindow(tester, const Size(1280, 800));
    await tester.pumpWidget(_landing(isSignedIn: true));

    expect(find.text('Open dashboard'), findsNWidgets(3));
    expect(find.text('Login'), findsNothing);
  });

  test('the website starts on the first page for any address', () {
    for (final address in ['/', '/home', '/start']) {
      final routes = AppRouter.landingInitialRoutes(address);
      expect(routes, hasLength(1));
      final first = routes.single as AppPageRoute;
      expect(first.routeName, AppRoutes.splash);
    }
  });
}
