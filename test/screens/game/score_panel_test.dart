import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/game/management.dart';
import 'package:lets_play_cities/base/repos.dart';
import 'package:lets_play_cities/base/users.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/common/d2/d2.dart';
import 'package:lets_play_cities/screens/game/score_panel.dart';

import '../../i18n/translations_harness.dart';
import 'fake_game_session.dart';

void main() {
  final t = AppLocale.ru.buildSync();

  late StreamController<GameEvent> events;

  setUp(() => events = StreamController<GameEvent>.broadcast());

  tearDown(() => events.close());

  Player player(String name, int score) => Player(
    LocalAccountInfo(name: name, picture: const PlaceholderPictureSource()),
  )..increaseScore(score);

  Future<void> pumpPanel(
    WidgetTester tester,
    UsersList users, {
    int timeLimit = 0,
    double textScale = 1,
  }) async {
    final repository = GameSessionRepository(
      FakeGameSession(events.stream, users, timeLimit: timeLimit),
    );

    await tester.pumpWidget(
      withTranslations(
        MaterialApp(
          theme: buildD2Theme(Brightness.light),
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(textScale)),
              child: Scaffold(
                body: RepositoryProvider.value(
                  value: repository,
                  child: RepositoryProvider.value(
                    value: repository.createGameServiceEventsRepository(),
                    child: const ScorePanel(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('ScorePanel shows letter and both players', (tester) async {
    final first = player('Аня', 12);
    final second = player('Борис', 7);
    await pumpPanel(tester, UsersList([first, second]));

    events.add(OnUserSwitchedEvent(first, [first, second]));
    events.add(const OnFirstCharChanged('м'));
    await tester.pump();

    expect(find.text('М'), findsOneWidget);
    expect(find.text('Аня'), findsOneWidget);
    expect(find.text('Борис'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.bySemanticsLabel(t.game.yourTurn), findsOneWidget);
  });

  testWidgets('ScorePanel shows any letter before the first move', (
    tester,
  ) async {
    final first = player('Аня', 0);
    final second = player('Борис', 0);
    await pumpPanel(tester, UsersList([first, second]));

    events.add(OnUserSwitchedEvent(first, [first, second]));
    events.add(const OnFirstCharChanged(''));
    await tester.pump();

    expect(find.text(t.game.letterAny), findsOneWidget);
  });

  testWidgets('ScorePanel shows the seconds left of the move', (tester) async {
    final first = player('Аня', 0);
    final second = player('Борис', 0);
    await pumpPanel(tester, UsersList([first, second]), timeLimit: 60);

    events.add(OnUserSwitchedEvent(first, [first, second]));
    events.add(const TimeEvent(14));
    await tester.pump();

    expect(find.text('0:14'), findsOneWidget);
    expect(find.bySemanticsLabel(t.game.secondsLeft(s: 14)), findsOneWidget);
  });

  testWidgets('score panel fits 320px at 1.3 text scale', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final first = player('Александра', 1234);
    final second = player('Константин', 9876);
    await pumpPanel(
      tester,
      UsersList([first, second]),
      timeLimit: 60,
      textScale: 1.3,
    );

    events.add(OnUserSwitchedEvent(second, [first, second]));
    events.add(const OnFirstCharChanged('н'));
    events.add(const TimeEvent(42));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Н'), findsOneWidget);
  });
}
