import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/game/game_config.dart';
import 'package:lets_play_cities/base/game/game_mode.dart';
import 'package:lets_play_cities/base/game/management.dart';
import 'package:lets_play_cities/base/game/turn_gate.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/base/repos.dart';
import 'package:lets_play_cities/base/stt/bloc/voice_recognition_bloc.dart';
import 'package:lets_play_cities/base/stt/voice_recognition_service.dart';
import 'package:lets_play_cities/base/users.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/common/d2/d2.dart';
import 'package:lets_play_cities/screens/game/game_layout.dart';
import 'package:lets_play_cities/screens/game/hotseat_handoff.dart';
import 'package:lets_play_cities/screens/game/hotseat_setup_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../i18n/translations_harness.dart';
import 'fake_game_session.dart';

/// A session whose last accepted word is set by the test.
class _HandoffSession extends FakeGameSession {
  String word = '';

  _HandoffSession(super.events, super.users, {super.timeLimit});

  @override
  String get lastAcceptedWord => word;
}

/// 320x640 at 1.3 text scale, the narrowest screen the app supports.
void _useNarrowScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(320, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget _app(Widget home, {double textScale = 1}) => withTranslations(
  MaterialApp(
    theme: buildD2Theme(Brightness.light),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: home,
  ),
);

void main() {
  final t = AppLocale.ru.buildSync();

  group('setup', () {
    late GamePreferences prefs;
    late List<GameConfig> started;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = SharedPreferencesGamePrefs(await SharedPreferences.getInstance());
      started = [];
    });

    Future<void> pumpSetup(WidgetTester tester, {double textScale = 1}) =>
        tester.pumpWidget(
          RepositoryProvider<GamePreferences>.value(
            value: prefs,
            child: _app(
              HotseatSetupScreen(
                gameRoute: (config) {
                  started.add(config);
                  return MaterialPageRoute<void>(
                    builder: (_) => const Text('game'),
                  );
                },
              ),
              textScale: textScale,
            ),
          ),
        );

    testWidgets('hotseat setup saves names', (tester) async {
      await pumpSetup(tester);

      expect(find.text(t.hotseat.passPhone), findsOneWidget);
      expect(
        find.text(t.hotseat.turnOf(name: t.hotseat.player1)),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextField).at(0), 'Аня');
      await tester.enterText(find.byType(TextField).at(1), 'Боря');
      await tester.pump();

      expect(find.text(t.hotseat.turnOf(name: 'Аня')), findsOneWidget);

      await tester.tap(find.text(t.hotseat.ready));
      await tester.pumpAndSettle();

      expect(prefs.hotseatNames, ['Аня', 'Боря']);
      expect(started.single.gameMode, GameMode.playerVsPlayer);
      expect(find.text('game'), findsOneWidget);
      expect(find.byType(HotseatSetupScreen), findsNothing);
    });

    testWidgets('setup starts the stored variant', (tester) async {
      prefs.gameVariant = GameVariant.route;
      await pumpSetup(tester);

      await tester.tap(find.text(t.hotseat.ready));
      await tester.pumpAndSettle();

      expect(started.single.variant, GameVariant.route);
    });

    testWidgets('setup shows the saved names', (tester) async {
      prefs.hotseatNames = ['Аня', 'Боря'];
      await pumpSetup(tester);

      expect(find.text('Аня'), findsOneWidget);
      expect(find.text('Боря'), findsOneWidget);
      expect(find.text(t.hotseat.turnOf(name: 'Аня')), findsOneWidget);
    });

    testWidgets('the pencil edits the name, «Готово» closes the keyboard', (
      tester,
    ) async {
      await pumpSetup(tester);

      final field = find.byType(TextField).first;
      expect(
        tester.widget<TextField>(field).textInputAction,
        TextInputAction.done,
      );
      expect(tester.widget<TextField>(field).focusNode!.hasFocus, isFalse);

      await tester.tap(
        find
            .byWidgetPredicate((w) => w is D2Icon && w.glyph == D2Glyph.edit)
            .first,
      );
      await tester.pump();
      expect(tester.widget<TextField>(field).focusNode!.hasFocus, isTrue);

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(tester.widget<TextField>(field).focusNode!.hasFocus, isFalse);
    });

    testWidgets('names are at most 10 characters', (tester) async {
      await pumpSetup(tester);

      await tester.enterText(find.byType(TextField).first, 'Александрина');
      await tester.pump();

      expect(find.text('Александри'), findsOneWidget);
    });

    testWidgets('setup fits 320px at 1.3 text scale', (tester) async {
      _useNarrowScreen(tester);
      await pumpSetup(tester, textScale: 1.3);

      expect(tester.takeException(), isNull);
    });
  });

  group('handoff', () {
    late StreamController<GameEvent> events;
    late Player first;
    late Player second;
    late _HandoffSession session;
    late TurnGate gate;
    late int tapsUnder;
    late int pops;

    setUp(() {
      events = StreamController<GameEvent>.broadcast();
      first = Player(
        const LocalAccountInfo(
          name: 'Аня',
          picture: PlaceholderPictureSource(),
        ),
      );
      second = Player(
        const LocalAccountInfo(
          name: 'Боря',
          picture: PlaceholderPictureSource(),
        ),
      );
      session = _HandoffSession(
        events.stream,
        UsersList([first, second]),
        timeLimit: 60,
      );
      gate = TurnGate();
      tapsUnder = 0;
      pops = 0;
    });

    tearDown(() => events.close());

    Future<void> pumpHandoff(WidgetTester tester, {double textScale = 1}) =>
        tester.pumpWidget(
          _app(
            Scaffold(
              body: PopScope(
                canPop: false,
                onPopInvokedWithResult: (_, _) => pops++,
                child: RepositoryProvider(
                  create: (_) => GameSessionRepository(session),
                  child: HotseatHandoff(
                    gate: gate,
                    child: Center(
                      child: TextButton(
                        onPressed: () => tapsUnder++,
                        child: const Text('under'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            textScale: textScale,
          ),
        );

    /// Plays the first move of [first]: the gate opens by itself for it.
    Future<void> playFirstMove(WidgetTester tester) async {
      var firstMoveStarted = false;
      gate.waitFor(first).then((_) => firstMoveStarted = true);
      await tester.pump();
      await tester.pump();

      expect(firstMoveStarted, isTrue);
      expect(find.text(t.hotseat.ready), findsNothing);

      first.increaseScore(14);
      events.add(
        Accepted('калуга', first, status: CityStatus.ok, countryCode: 1),
      );
      session.word = 'калуга';
    }

    testWidgets('handoff shows next player and releases gate', (tester) async {
      await pumpHandoff(tester);
      await playFirstMove(tester);

      var secondMoveStarted = false;
      gate.waitFor(second).then((_) => secondMoveStarted = true);
      await tester.pump();
      await tester.pump();

      expect(find.text(t.hotseat.passPhone), findsOneWidget);
      expect(find.text(t.hotseat.turnOf(name: 'Боря')), findsOneWidget);
      expect(find.text('Калуга', findRichText: true), findsOneWidget);
      expect(find.text('А'), findsOneWidget);
      expect(find.text('14'), findsOneWidget);
      expect(find.text('1:00'), findsOneWidget);
      // The names are read only during the game.
      expect(find.byType(TextField), findsNothing);

      await tester.tap(find.text('under'), warnIfMissed: false);
      await tester.pump();
      expect(tapsUnder, 0);

      await tester.tap(find.text(t.hotseat.ready));
      await tester.pump();
      await tester.pump();

      expect(secondMoveStarted, isTrue);
      expect(gate.waiting.value, isNull);
      expect(find.text(t.hotseat.ready), findsNothing);

      await tester.tap(find.text('under'));
      expect(tapsUnder, 1);
    });

    testWidgets('back on the handoff asks the game to go to the menu', (
      tester,
    ) async {
      await pumpHandoff(tester);
      await playFirstMove(tester);
      gate.waitFor(second).ignore();
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byTooltip(t.d2.back));
      await tester.pump();

      expect(pops, 1);
      expect(gate.waiting.value, same(second));
    });

    /// The real game layout under the handoff, at 320px and 1.3 text scale.
    Future<void> pumpGame(WidgetTester tester) async {
      _useNarrowScreen(tester);
      final repository = GameSessionRepository(session);
      final voice = VoiceRecognitionBloc(
        repository.sendInputWord,
        StubVoiceRecognitionService(),
      );
      addTearDown(voice.close);
      const config = GameConfig(gameMode: GameMode.playerVsPlayer);

      await tester.pumpWidget(
        _app(
          Scaffold(
            body: MultiRepositoryProvider(
              providers: [
                RepositoryProvider.value(value: repository),
                RepositoryProvider.value(
                  value: repository.createGameServiceEventsRepository(),
                ),
              ],
              child: BlocProvider.value(
                value: voice,
                child: HotseatHandoff(
                  gate: gate,
                  child: GameLayout(config, onRegisterInputClear: (_) {}),
                ),
              ),
            ),
          ),
          textScale: 1.3,
        ),
      );
    }

    testWidgets('the game menu is out of reach under the handoff', (
      tester,
    ) async {
      await pumpGame(tester);
      await playFirstMove(tester);
      events.add(OnUserSwitchedEvent(first, [first, second]));
      await tester.pump();

      // The menu is opened just before the city is accepted.
      await tester.tap(find.text(t.game.pause));
      await tester.pumpAndSettle();
      expect(find.text(t.game.surrenderMenu), findsOneWidget);

      gate.waitFor(second).ignore();
      await tester.pumpAndSettle();

      expect(find.text(t.hotseat.ready), findsOneWidget);
      expect(find.text(t.game.surrenderMenu), findsNothing);

      await tester.tap(find.text(t.game.pause), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text(t.game.surrenderMenu), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the city field takes the focus after «Я готов»', (
      tester,
    ) async {
      await pumpGame(tester);
      await playFirstMove(tester);
      gate.waitFor(second).ignore();
      await tester.pumpAndSettle();

      final field = find.byType(TextField);
      expect(tester.widget<TextField>(field).focusNode?.hasFocus, isFalse);

      await tester.tap(find.text(t.hotseat.ready));
      await tester.pumpAndSettle();

      expect(tester.widget<TextField>(field).focusNode?.hasFocus, isTrue);
    });

    testWidgets('handoff fits 320px at 1.3 text scale', (tester) async {
      _useNarrowScreen(tester);
      await pumpHandoff(tester, textScale: 1.3);
      await playFirstMove(tester);
      gate.waitFor(second).ignore();
      await tester.pump();
      await tester.pump();

      expect(find.text(t.hotseat.ready), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
