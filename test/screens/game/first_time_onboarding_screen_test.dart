import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/game/game_config.dart';
import 'package:lets_play_cities/base/game/game_mode.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/game/first_time_onboarding_screen.dart';

import '../../i18n/translations_harness.dart';

void main() {
  final navigatorKey = GlobalKey<NavigatorState>();
  final t = AppLocale.ru.buildSync();

  Future<void> openRules(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      withTranslations(
        MaterialApp(navigatorKey: navigatorKey, home: const Text('home')),
      ),
    );
    navigatorKey.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => const Text('game')),
    );
    await tester.pumpAndSettle();

    navigatorKey.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const FirstTimeOnBoardingScreen(
          gameConfig: GameConfig(gameMode: GameMode.playerVsAndroid),
          replay: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('next turns the pages, play on the last one goes back', (
    tester,
  ) async {
    await openRules(tester);

    expect(find.text(t.firstTimeScreen.step1Title), findsOneWidget);

    await tester.tap(find.text(t.firstTimeScreen.next));
    await tester.pumpAndSettle();
    expect(find.text(t.firstTimeScreen.step2Title), findsOneWidget);

    await tester.tap(find.text(t.firstTimeScreen.next));
    await tester.pumpAndSettle();
    expect(find.text(t.firstTimeScreen.step3Title), findsOneWidget);
    expect(find.text(t.firstTimeScreen.next), findsNothing);

    await tester.tap(find.text(t.home.play));
    await tester.pumpAndSettle();

    expect(find.text('game'), findsOneWidget);
    expect(find.byType(FirstTimeOnBoardingScreen), findsNothing);
  });

  testWidgets('swiping turns the page', (tester) async {
    await openRules(tester);

    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();

    expect(find.text(t.firstTimeScreen.step2Title), findsOneWidget);
  });

  testWidgets('skip closes the rules replay', (tester) async {
    await openRules(tester);

    await tester.tap(find.text(t.firstTimeScreen.skip));
    await tester.pumpAndSettle();

    expect(find.text('game'), findsOneWidget);
    expect(find.byType(FirstTimeOnBoardingScreen), findsNothing);
  });

  testWidgets('pages fit 320 px with a large font', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      withTranslations(
        MaterialApp(
          builder: (context, w) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.3)),
            child: w!,
          ),
          home: const FirstTimeOnBoardingScreen(
            gameConfig: GameConfig(gameMode: GameMode.playerVsAndroid),
            replay: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text(t.firstTimeScreen.next));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
