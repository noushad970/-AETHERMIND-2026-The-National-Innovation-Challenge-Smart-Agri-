import 'package:ai_agri_assistant/core/layout/adaptive_two_pane.dart';
import 'package:ai_agri_assistant/core/layout/desktop_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void _setWindow(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget _box(String label, [double height = 80]) =>
    SizedBox(height: height, child: Text(label));

Widget _app({
  required bool desktop,
  bool lazy = true,
  bool secondaryOnLeft = false,
  bool withSecondary = true,
}) => MaterialApp(
  home: DesktopScope(
    isDesktop: desktop,
    child: Scaffold(
      body: AdaptiveTwoPane(
        lazy: lazy,
        secondaryOnLeft: secondaryOnLeft,
        top: [_box('top')],
        primary: [_box('first'), _box('second')],
        secondary: [if (withSecondary) _box('side')],
        bottom: [_box('bottom')],
      ),
    ),
  ),
);

Offset _at(WidgetTester tester, String text) =>
    tester.getTopLeft(find.text(text));

void main() {
  for (final lazy in [true, false]) {
    testWidgets('phones keep one column in order (lazy: $lazy)', (
      tester,
    ) async {
      _setWindow(tester, const Size(390, 844));
      await tester.pumpWidget(
        _app(desktop: false, lazy: lazy, secondaryOnLeft: true),
      );

      final order = ['top', 'first', 'second', 'side', 'bottom'];
      for (var i = 1; i < order.length; i++) {
        expect(_at(tester, order[i]).dx, _at(tester, order[0]).dx);
        expect(
          _at(tester, order[i]).dy,
          greaterThan(_at(tester, order[i - 1]).dy),
        );
      }
    });
  }

  testWidgets('desktop windows use two columns', (tester) async {
    _setWindow(tester, const Size(1000, 800));
    await tester.pumpWidget(_app(desktop: true));

    expect(_at(tester, 'side').dy, _at(tester, 'first').dy);
    expect(_at(tester, 'side').dx, greaterThan(_at(tester, 'first').dx));
    expect(_at(tester, 'top').dy, lessThan(_at(tester, 'first').dy));
    expect(_at(tester, 'bottom').dy, greaterThan(_at(tester, 'second').dy));
  });

  testWidgets('the second column can be shown on the left', (tester) async {
    _setWindow(tester, const Size(1000, 800));
    await tester.pumpWidget(_app(desktop: true, secondaryOnLeft: true));

    expect(_at(tester, 'side').dy, _at(tester, 'first').dy);
    expect(_at(tester, 'side').dx, lessThan(_at(tester, 'first').dx));
  });

  testWidgets('a page without a second column stays narrow', (tester) async {
    _setWindow(tester, const Size(1200, 800));
    await tester.pumpWidget(_app(desktop: true, withSecondary: false));

    expect(
      _at(tester, 'first').dx,
      (1200 - AdaptiveTwoPane.singleColumnWidth) / 2,
    );
  });

  testWidgets('short desktop pages still fill the height', (tester) async {
    _setWindow(tester, const Size(1000, 800));
    await tester.pumpWidget(_app(desktop: true));

    expect(tester.getSize(find.byType(SingleChildScrollView)).height, 800);
  });
}
