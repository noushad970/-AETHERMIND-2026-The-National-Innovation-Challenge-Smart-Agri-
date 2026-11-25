import 'package:ai_agri_assistant/core/routes/app_routes.dart';
import 'package:ai_agri_assistant/core/theme/app_theme.dart';
import 'package:ai_agri_assistant/features/home/presentation/widgets/desktop_home_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void _setWindow(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget _home({
  bool isBn = false,
  ThemeData? theme,
  ValueChanged<String>? onOpen,
}) => MaterialApp(
  theme: theme ?? AppTheme.lightTheme(),
  home: Scaffold(
    body: DesktopHomeView(
      isBn: isBn,
      greeting: 'Good morning',
      displayName: 'A farmer with a very long display name',
      temperature: '31°C',
      condition: 'Partly cloudy',
      activeCropCount: 7,
      heroBackground: const ColoredBox(color: Colors.green),
      activeCrops: const SizedBox(height: 120, child: Text('active crops')),
      recentCrops: const SizedBox(height: 120, child: Text('recent crops')),
      sections: [
        DesktopFeatureSection(
          title: 'My Farm',
          description: 'Crops and ponds',
          cards: [for (var i = 0; i < 4; i++) Card(child: Text('card $i'))],
        ),
      ],
      onOpen: onOpen ?? (_) {},
    ),
  ),
);

void main() {
  // Content widths beside the sidebar on small and large desktop windows.
  for (final size in const [Size(760, 700), Size(1016, 800), Size(1656, 1000)]) {
    testWidgets('lays out without overflow at ${size.width}', (tester) async {
      _setWindow(tester, size);
      for (final isBn in [false, true]) {
        await tester.pumpWidget(_home(isBn: isBn));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Scroll in steps so that every section is painted.
        for (var step = 0; step < 12; step++) {
          await tester.drag(
            find.byType(CustomScrollView),
            const Offset(0, -350),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        await tester.pumpWidget(const SizedBox());
      }
    });
  }

  testWidgets('works with the dark theme', (tester) async {
    _setWindow(tester, const Size(1016, 800));
    await tester.pumpWidget(_home(theme: AppTheme.darkTheme()));

    expect(find.text('Smarter farming for every field'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hero buttons and figures open their pages', (tester) async {
    _setWindow(tester, const Size(1400, 1200));
    final opened = <String>[];
    await tester.pumpWidget(_home(onOpen: opened.add));

    await tester.tap(find.text('Scan a crop disease'));
    await tester.tap(find.text('Ask the AI advisor'));
    await tester.tap(find.text('Add a crop'));
    await tester.tap(find.text('Irrigation AI'));
    await tester.tap(find.byKey(const ValueKey('stat:/crop/list')));

    expect(opened, [
      AppRoutes.diseaseDetect,
      AppRoutes.chatbot,
      AppRoutes.addCrop,
      AppRoutes.smartIrrigation,
      AppRoutes.cropList,
    ]);
    expect(find.text('7'), findsOneWidget);
  });

  testWidgets('puts the crop panels side by side when wide', (tester) async {
    _setWindow(tester, const Size(1400, 1400));
    await tester.pumpWidget(_home());

    expect(
      tester.getTopLeft(find.text('active crops')).dy,
      tester.getTopLeft(find.text('recent crops')).dy,
    );
  });
}
