import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/game/game_config.dart';
import 'package:lets_play_cities/base/game/game_mode.dart';
import 'package:lets_play_cities/screens/game/first_time_onboarding_screen.dart';

void main() {
  final navigatorKey = GlobalKey<NavigatorState>();

  Future<void> openRules(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(navigatorKey: navigatorKey, home: const Text('home')),
    );
    navigatorKey.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => const Text('game')),
    );
    await tester.pumpAndSettle();

    navigatorKey.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const FirstTimeOnBoardingScreen(
          strings: ['first', 'second'],
          duration: Duration(milliseconds: 100),
          gameConfig: GameConfig(gameMode: GameMode.playerVsAndroid),
          replay: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the rules replay goes back to the game', (tester) async {
    await openRules(tester);

    expect(find.text('game'), findsOneWidget);
    expect(find.byType(FirstTimeOnBoardingScreen), findsNothing);
  });
}
