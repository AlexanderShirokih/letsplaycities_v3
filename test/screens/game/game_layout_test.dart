import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/game/game_config.dart';
import 'package:lets_play_cities/base/game/game_mode.dart';
import 'package:lets_play_cities/base/game/management.dart';
import 'package:lets_play_cities/base/repos.dart';
import 'package:lets_play_cities/base/stt/bloc/voice_recognition_bloc.dart';
import 'package:lets_play_cities/base/stt/voice_recognition_service.dart';
import 'package:lets_play_cities/base/users.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/common/d2/d2.dart';
import 'package:lets_play_cities/screens/game/cities_list.dart';
import 'package:lets_play_cities/screens/game/game_layout.dart';

import '../../i18n/translations_harness.dart';
import 'fake_game_session.dart';

void main() {
  final t = AppLocale.ru.buildSync();

  late StreamController<GameEvent> events;
  late Player first;
  late Player second;

  setUp(() {
    events = StreamController<GameEvent>.broadcast();
    first = Player(
      const LocalAccountInfo(
        name: 'Александра',
        picture: PlaceholderPictureSource(),
      ),
    )..increaseScore(1234);
    second = Player(
      const LocalAccountInfo(
        name: 'Константин',
        picture: PlaceholderPictureSource(),
      ),
    )..increaseScore(9876);
  });

  tearDown(() => events.close());

  Future<void> pumpLayout(WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(tester.view.reset);

    final repository = GameSessionRepository(
      FakeGameSession(
        events.stream,
        UsersList([first, second]),
        mode: GameMode.playerVsAndroid,
        timeLimit: 60,
      ),
    );
    final voice = VoiceRecognitionBloc(
      repository.sendInputWord,
      StubVoiceRecognitionService(),
    );
    addTearDown(voice.close);

    await tester.pumpWidget(
      withTranslations(
        MaterialApp(
          theme: buildD2Theme(Brightness.light),
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.3)),
              child: Builder(
                // Read above the Scaffold, as the game screen does.
                builder: (context) => Scaffold(
                  body: MultiRepositoryProvider(
                    providers: [
                      RepositoryProvider.value(value: repository),
                      RepositoryProvider.value(
                        value: repository.createGameServiceEventsRepository(),
                      ),
                    ],
                    child: BlocProvider.value(
                      value: voice,
                      child: GameLayout(
                        const GameConfig(gameMode: GameMode.playerVsAndroid),
                        keyboardOpen:
                            MediaQuery.viewInsetsOf(context).bottom > 0,
                        onRegisterInputClear: (_) {},
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    events.add(OnUserSwitchedEvent(first, [first, second]));
    events.add(const OnFirstCharChanged('м'));
    events.add(const TimeEvent(42));
    for (final city in ['калуга', 'анадырь', 'рязань', 'норильск']) {
      events.add(Accepted(city, first, status: CityStatus.ok));
    }
    await tester.pump();
  }

  /// Delivers [result] and lets the result bar open.
  Future<void> showResult(
    WidgetTester tester,
    WordCheckingResult result,
  ) async {
    events.add(result);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1500));
  }

  void expectLastBubbleVisible(WidgetTester tester) {
    final feed = tester.getRect(find.byType(CitiesList));
    final last = tester.getRect(find.byType(GameItemListTile).first);

    expect(feed.height, greaterThanOrEqualTo(GameLayout.minFeedHeight));
    expect(last.top, greaterThanOrEqualTo(feed.top));
    expect(last.bottom, lessThanOrEqualTo(feed.bottom));
  }

  testWidgets('game fits 320px at 1.3 text scale with the keyboard open', (
    tester,
  ) async {
    await pumpLayout(tester);
    expect(tester.takeException(), isNull);
    expect(find.text(t.game.cityOnLetter), findsNothing);
    expectLastBubbleVisible(tester);

    await showResult(tester, const Corrections({'москва', 'мурманск'}));
    expect(tester.takeException(), isNull);
    expect(find.text('Мурманск'), findsOneWidget);
    expectLastBubbleVisible(tester);

    await showResult(tester, const NotFound('масквабадская'));
    expect(tester.takeException(), isNull);
    expect(
      find.text(t.game.unknownCity(city: 'Масквабадская')),
      findsOneWidget,
    );
    expectLastBubbleVisible(tester);
  });

  testWidgets('city field hints the letter of the move', (tester) async {
    await pumpLayout(tester);

    expect(find.text(t.game.cityOnLetterHint(letter: 'М')), findsOneWidget);

    events.add(const OnFirstCharChanged(''));
    await tester.pump();
    expect(find.text(t.game.cityHint), findsOneWidget);
  });
}
