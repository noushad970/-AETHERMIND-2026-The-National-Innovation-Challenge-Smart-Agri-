import 'package:ai_agri_assistant/core/layout/app_navigation.dart';
import 'package:ai_agri_assistant/core/layout/desktop_page_frame.dart';
import 'package:ai_agri_assistant/core/layout/desktop_scope.dart';
import 'package:ai_agri_assistant/core/layout/desktop_shell.dart';
import 'package:ai_agri_assistant/core/layout/desktop_sidebar.dart';
import 'package:ai_agri_assistant/core/routes/app_router.dart';
import 'package:ai_agri_assistant/core/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void _setWindow(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

const _desktop = Size(1280, 800);
const _phone = Size(390, 844);

class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int count = 0;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width.round();
    final desktop = DesktopScope.of(context);
    return GestureDetector(
      onTap: () => setState(() => count++),
      child: Scaffold(body: Text('count $count, $width, $desktop')),
    );
  }
}

Widget _shellApp(ValueNotifier<String?> route) => MaterialApp(
  builder: (context, child) => DesktopShell(
    currentRoute: route,
    sidebarBuilder: (_, name) => Material(child: Text('sidebar $name')),
    child: child!,
  ),
  home: const _Counter(),
);

void main() {
  group('DesktopShell', () {
    testWidgets('shows the sidebar beside the page on wide windows', (
      tester,
    ) async {
      _setWindow(tester, _desktop);
      await tester.pumpWidget(_shellApp(ValueNotifier(AppRoutes.home)));

      expect(find.text('sidebar /home'), findsOneWidget);
      final pageWidth = (1280 - DesktopShell.sidebarWidth).round();
      expect(find.text('count 0, $pageWidth, true'), findsOneWidget);
    });

    testWidgets('keeps the phone layout unchanged', (tester) async {
      _setWindow(tester, _phone);
      await tester.pumpWidget(_shellApp(ValueNotifier(AppRoutes.home)));

      expect(find.textContaining('sidebar'), findsNothing);
      expect(find.text('count 0, 390, false'), findsOneWidget);
    });

    testWidgets('hides the sidebar on the login page', (tester) async {
      _setWindow(tester, _desktop);
      final route = ValueNotifier<String?>(AppRoutes.login);
      await tester.pumpWidget(_shellApp(route));
      expect(find.textContaining('sidebar'), findsNothing);

      route.value = AppRoutes.weatherScreen;
      await tester.pump();
      expect(find.text('sidebar /weather'), findsOneWidget);
    });

    testWidgets('blocks the sidebar while a dialog is open', (tester) async {
      _setWindow(tester, _desktop);
      final barrier = ValueNotifier<Color?>(null);
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => DesktopShell(
            currentRoute: ValueNotifier(AppRoutes.home),
            barrier: barrier,
            sidebarBuilder: (_, _) => Material(
              child: InkWell(onTap: () => taps++, child: const Text('menu')),
            ),
            child: child!,
          ),
          home: const Scaffold(),
        ),
      );

      barrier.value = Colors.black54;
      await tester.pump();
      await tester.tap(find.text('menu'), warnIfMissed: false);
      expect(taps, 0);

      barrier.value = null;
      await tester.pump();
      await tester.tap(find.text('menu'));
      expect(taps, 1);
    });

    testWidgets('resizing the window keeps page state', (tester) async {
      _setWindow(tester, _desktop);
      await tester.pumpWidget(_shellApp(ValueNotifier(AppRoutes.home)));
      await tester.tap(find.textContaining('count 0'));
      await tester.pump();

      tester.view.physicalSize = _phone;
      await tester.pumpAndSettle();

      expect(find.text('count 1, 390, false'), findsOneWidget);
    });
  });

  group('DesktopSidebar', () {
    Widget sidebar({
      required ValueChanged<String> onSelect,
      bool isBn = false,
    }) => MaterialApp(
      home: Row(
        children: [
          SizedBox(
            width: DesktopShell.sidebarWidth,
            child: DesktopSidebar(
              currentRoute: AppRoutes.cropDetail,
              isBn: isBn,
              isDark: false,
              userName: 'A farmer with a very long display name',
              unreadCount: 3,
              onSelect: onSelect,
              onToggleTheme: () {},
              onToggleLanguage: () {},
              onLogout: () {},
            ),
          ),
        ],
      ),
    );

    testWidgets('every button reports its page', (tester) async {
      _setWindow(tester, const Size(1280, 1600));
      final selected = <String>[];
      await tester.pumpWidget(sidebar(onSelect: selected.add));

      final routes = [
        for (final group in sidebarGroups)
          for (final item in group.items) item.route,
      ];
      for (final route in routes) {
        await tester.tap(find.byKey(ValueKey('sidebar:$route')));
      }

      expect(selected, routes);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('has Bangla labels and fits a short window', (tester) async {
      _setWindow(tester, const Size(1024, 600));
      await tester.pumpWidget(sidebar(onSelect: (_) {}, isBn: true));

      expect(find.text('হোম'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    test('detail pages highlight their list button', () {
      expect(sidebarSelectionFor(AppRoutes.cropDetail), AppRoutes.cropList);
      expect(sidebarSelectionFor(AppRoutes.fishLiveTrack), AppRoutes.fishList);
      expect(sidebarSelectionFor(AppRoutes.settings), AppRoutes.settings);
    });

    test('every button leads to a real page', () {
      for (final group in sidebarGroups) {
        for (final item in group.items) {
          final route = AppRouter.generate(RouteSettings(name: item.route));
          expect(route, isA<AppPageRoute>(), reason: item.route);
          expect((route! as AppPageRoute).routeName, item.route);
        }
      }
    });
  });

  testWidgets('RouteTracker follows the top page', (tester) async {
    final tracker = RouteTracker();
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        navigatorObservers: [tracker],
        onGenerateRoute: (settings) => AppPageRoute(
          routeName: settings.name,
          builder: (_) => Scaffold(body: Text('page ${settings.name}')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tracker.current.value, '/');

    navigator.currentState!.pushNamed('/list');
    await tester.pumpAndSettle();
    navigator.currentState!.pushNamed('/detail');
    await tester.pumpAndSettle();
    expect(tracker.current.value, '/detail');

    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(tracker.current.value, '/list');

    // A dialog is not a page, so the selection stays put.
    showDialog<void>(
      context: navigator.currentState!.overlay!.context,
      builder: (_) => const AlertDialog(title: Text('dialog')),
    );
    await tester.pumpAndSettle();
    expect(tracker.current.value, '/list');
    expect(tracker.barrier.value, isNotNull);
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(tracker.barrier.value, isNull);

    navigator.currentState!.pushReplacementNamed('/other');
    await tester.pumpAndSettle();
    expect(tracker.current.value, '/other');

    navigator.currentState!.pushNamedAndRemoveUntil('/settings', (_) => false);
    await tester.pumpAndSettle();
    expect(tracker.current.value, '/settings');
  });

  group('DesktopPageFrame', () {
    Widget framed(DesktopPageStyle style, {required bool desktop}) =>
        MaterialApp(
          home: DesktopScope(
            isDesktop: desktop,
            child: DesktopPageFrame(
              style: style,
              child: Builder(
                builder: (context) => Scaffold(
                  body: Text('${MediaQuery.sizeOf(context).width.round()}'),
                ),
              ),
            ),
          ),
        );

    testWidgets('limits the page width on desktop', (tester) async {
      _setWindow(tester, const Size(1600, 900));
      await tester.pumpWidget(framed(DesktopPageStyle.form, desktop: true));

      expect(tester.getSize(find.byType(Scaffold)).width, 760);
      expect(find.text('760'), findsOneWidget);
    });

    testWidgets('adds a welcome panel to the login page', (tester) async {
      _setWindow(tester, const Size(1100, 800));
      await tester.pumpWidget(framed(DesktopPageStyle.auth, desktop: true));

      expect(find.text('Smart Agri BD'), findsOneWidget);
      expect(tester.getSize(find.byType(Scaffold)).width, 560);
      expect(tester.takeException(), isNull);
    });

    testWidgets('leaves phones alone', (tester) async {
      _setWindow(tester, _phone);
      await tester.pumpWidget(framed(DesktopPageStyle.auth, desktop: false));

      expect(find.text('Smart Agri BD'), findsNothing);
      expect(tester.getSize(find.byType(Scaffold)), _phone);
    });
  });
}
