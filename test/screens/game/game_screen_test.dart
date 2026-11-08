import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/screens/game/game_screen.dart';

void main() {
  final navigatorKey = GlobalKey<NavigatorState>();
  late BuildContext gameContext;

  /// Shows 'home' with a 'game' route pushed over it.
  Future<void> openGame(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(navigatorKey: navigatorKey, home: const Text('home')),
    );
    navigatorKey.currentState!.push(
      MaterialPageRoute<void>(
        builder: (context) {
          gameContext = context;
          return const Text('game');
        },
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> showResults(WidgetTester tester) async {
    replaceGameRoute(
      gameContext,
      MaterialPageRoute<void>(builder: (_) => const Text('results')),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('results replace the game route', (tester) async {
    await openGame(tester);

    await showResults(tester);
    navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
  });

  testWidgets(
    'results close a dialog open over the game and replace the game',
    (tester) async {
      await openGame(tester);
      showDialog<bool>(
        context: gameContext,
        builder: (_) => const Text('dialog'),
      );
      await tester.pumpAndSettle();

      await showResults(tester);

      expect(find.text('results'), findsOneWidget);
      expect(find.text('dialog'), findsNothing);

      navigatorKey.currentState!.pop();
      await tester.pumpAndSettle();

      expect(find.text('home'), findsOneWidget);
      expect(find.text('game'), findsNothing);
    },
  );

  testWidgets('results arriving while the game is closing keep the menu', (
    tester,
  ) async {
    await openGame(tester);
    navigatorKey.currentState!.pop();
    await tester.pump(const Duration(milliseconds: 100));

    await showResults(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('home'), findsOneWidget);
    expect(find.text('results'), findsNothing);
  });
}
