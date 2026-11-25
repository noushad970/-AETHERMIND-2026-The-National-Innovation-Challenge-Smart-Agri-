import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ai_agri_assistant/core/providers/animation_mode_provider.dart';
import 'package:ai_agri_assistant/core/providers/locale_provider.dart';
import 'package:ai_agri_assistant/core/widgets/animation_mode_chooser.dart';
import 'package:ai_agri_assistant/core/widgets/live_pulse_badge.dart';

void main() {
  group('AnimationModeProvider', () {
    test('defaults to animated and has not chosen yet', () async {
      SharedPreferences.setMockInitialValues({});
      final p = AnimationModeProvider();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(p.isLoaded, isTrue);
      expect(p.isAnimated, isTrue);
      expect(p.hasChosen, isFalse);
    });

    test('loads a saved static choice', () async {
      SharedPreferences.setMockInitialValues({
        AnimationModeProvider.prefKey: 'static',
      });
      final p = AnimationModeProvider();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(p.isStatic, isTrue);
      expect(p.hasChosen, isTrue);
    });

    test('setMode persists and marks the choice as made', () async {
      SharedPreferences.setMockInitialValues({});
      final p = AnimationModeProvider();
      await Future<void>.delayed(Duration.zero);
      await p.setMode(AnimationMode.staticMode);
      expect(p.isStatic, isTrue);
      expect(p.hasChosen, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AnimationModeProvider.prefKey), 'static');
    });
  });

  Widget host(AnimationModeProvider mode, Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AnimationModeProvider>.value(value: mode),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  testWidgets('LivePulseBadge stops pulsing in static mode', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final mode = AnimationModeProvider(loadOnCreate: false);
    await tester.pumpWidget(host(mode, const LivePulseBadge()));
    expect(tester.hasRunningAnimations, isTrue);

    await mode.setMode(AnimationMode.staticMode);
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);

    await mode.setMode(AnimationMode.animated);
    await tester.pump();
    expect(tester.hasRunningAnimations, isTrue);
  });

  testWidgets('chooser sheet saves the selected mode', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final mode = AnimationModeProvider(loadOnCreate: false);
    await tester.pumpWidget(
      host(
        mode,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showAnimationModeChooser(context),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.speed_rounded));
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(mode.isStatic, isTrue);
    expect(mode.hasChosen, isTrue);
  });
}
