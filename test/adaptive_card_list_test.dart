import 'package:ai_agri_assistant/core/layout/adaptive_card_list.dart';
import 'package:ai_agri_assistant/core/layout/desktop_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void _setWindow(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget _app({required bool desktop, Widget? separator}) => MaterialApp(
  home: DesktopScope(
    isDesktop: desktop,
    child: Scaffold(
      body: AdaptiveCardList(
        minItemWidth: 400,
        separator: separator,
        header: const [Text('header')],
        footer: const [Text('footer')],
        itemCount: 5,
        // Cards of different heights, as in the real lists.
        itemBuilder: (_, i) =>
            SizedBox(height: 60.0 + i * 10, child: Text('item $i')),
      ),
    ),
  ),
);

Offset _at(WidgetTester tester, String text) =>
    tester.getTopLeft(find.text(text));

void main() {
  testWidgets('phones keep a single column', (tester) async {
    _setWindow(tester, const Size(390, 844));
    await tester.pumpWidget(
      _app(desktop: false, separator: const Divider(height: 1)),
    );

    expect(_at(tester, 'item 1').dx, _at(tester, 'item 0').dx);
    expect(_at(tester, 'item 1').dy, greaterThan(_at(tester, 'item 0').dy));
    expect(find.byType(Divider), findsNWidgets(4));
    expect(find.text('footer'), findsOneWidget);
  });

  testWidgets('desktop windows place cards side by side', (tester) async {
    _setWindow(tester, const Size(1000, 800));
    await tester.pumpWidget(_app(desktop: true));

    expect(_at(tester, 'item 1').dy, _at(tester, 'item 0').dy);
    expect(_at(tester, 'item 1').dx, greaterThan(_at(tester, 'item 0').dx));
    // The last row has a single card, aligned with the first column.
    expect(_at(tester, 'item 4').dx, _at(tester, 'item 0').dx);
    expect(_at(tester, 'header').dy, lessThan(_at(tester, 'item 0').dy));
    expect(_at(tester, 'footer').dy, greaterThan(_at(tester, 'item 4').dy));
  });

  testWidgets('wide windows use at most three columns', (tester) async {
    _setWindow(tester, const Size(1900, 900));
    await tester.pumpWidget(
      _app(desktop: true, separator: const Divider(height: 1)),
    );

    expect(_at(tester, 'item 2').dy, _at(tester, 'item 0').dy);
    expect(_at(tester, 'item 3').dy, greaterThan(_at(tester, 'item 0').dy));
    expect(find.byType(Divider), findsNothing);
  });

  test('rows are rounded up', () {
    expect(AdaptiveCardRow.rowCount(0, 2), 0);
    expect(AdaptiveCardRow.rowCount(5, 1), 5);
    expect(AdaptiveCardRow.rowCount(5, 2), 3);
    expect(AdaptiveCardRow.rowCount(6, 3), 2);
  });
}
