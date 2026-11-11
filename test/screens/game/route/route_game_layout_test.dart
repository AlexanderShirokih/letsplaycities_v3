import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/dictionary.dart';
import 'package:lets_play_cities/base/game/game_config.dart';
import 'package:lets_play_cities/base/game/game_mode.dart';
import 'package:lets_play_cities/base/game/management.dart';
import 'package:lets_play_cities/base/game/rules/route_rules.dart';
import 'package:lets_play_cities/base/geo/route_data.dart';
import 'package:lets_play_cities/base/repos.dart';
import 'package:lets_play_cities/base/stt/bloc/voice_recognition_bloc.dart';
import 'package:lets_play_cities/base/stt/voice_recognition_service.dart';
import 'package:lets_play_cities/base/users.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/common/design/design.dart';
import 'package:lets_play_cities/screens/game/hotseat_turn_view.dart';
import 'package:lets_play_cities/screens/game/route/route_format.dart';
import 'package:lets_play_cities/screens/game/route/route_game_layout.dart';

import '../../../base/geo/geo_test_data.dart';
import '../../../i18n/translations_harness.dart';
import '../fake_game_session.dart';

class _FakeDictionary extends Fake implements DictionaryService {}

/// Route rules that report a fixed [RouteState]
class _FixedRouteRules extends RouteRules {
  final RouteState fixed;

  _FixedRouteRules(this.fixed) : super(geoIndexOf(const {}), 2);

  @override
  RouteState get state => fixed;

  @override
  Stream<RouteState> get states => Stream.value(fixed);
}

const _nbsp = '\u00A0';

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
    );
    second = Player(
      const LocalAccountInfo(
        name: 'Константин',
        picture: PlaceholderPictureSource(),
      ),
    );
  });

  tearDown(() => events.close());

  /// 8 moves of [first] and 8 of [second]: the last one is Кадис of 2330 km,
  /// the first player skipped the move before it.
  RouteState buildState() {
    const cities = [
      'анадырь', 'рига', 'адлер', 'рим', 'мадрид', 'дублин', 'нант', //
      'тула', 'анкара', 'архангельск', 'казань', 'ницца', 'анапа',
      'любек',
    ];
    final legs = <RouteLeg>[
      for (var i = 0; i < cities.length; i++)
        RouteLeg(
          owner: i.isEven ? first : second,
          city: cities[i],
          countryCode: 1,
          point: null,
          km: 1000,
        ),
      RouteLeg(owner: first, city: null, countryCode: 0, point: null, km: 0),
      RouteLeg(
        owner: second,
        city: 'кадис',
        countryCode: 1,
        point: null,
        km: 2330,
      ),
    ];

    return RouteState(
      legs: legs,
      km: Map<User, int>.identity()
        ..[first] = 12480
        ..[second] = 10950,
      movesDone: legs.length,
    );
  }

  Future<void> pumpLayout(
    WidgetTester tester, {
    Size size = const Size(360, 760),
    double textScale = 1,
    double keyboard = 0,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
    addTearDown(tester.view.reset);

    final repository = GameSessionRepository(
      FakeGameSession(
        events.stream,
        UsersList([first, second]),
        mode: GameMode.playerVsPlayer,
        timeLimit: 60,
        rules: _FixedRouteRules(buildState()),
      ),
      routeData: RouteData(
        _FakeDictionary(),
        geoIndexOf(const {}),
        emptyWorld(),
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
          theme: buildAppTheme(Brightness.light),
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(textScale)),
              child: Scaffold(
                body: MultiRepositoryProvider(
                  providers: [
                    RepositoryProvider.value(value: repository),
                    RepositoryProvider.value(
                      value: repository.createGameServiceEventsRepository(),
                    ),
                  ],
                  child: BlocProvider.value(
                    value: voice,
                    child: RouteGameLayout(
                      const GameConfig(
                        gameMode: GameMode.playerVsPlayer,
                        variant: GameVariant.route,
                      ),
                      onRegisterInputClear: (_) {},
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
    events.add(const OnFirstCharChanged('с'));
    events.add(const TimeEvent(42));
    await tester.pump();
    await tester.pump();
  }

  test('formats km with non-breaking spaces between thousands', () {
    expect(formatKm(0), '0');
    expect(formatKm(900), '900');
    expect(formatKm(2330), '2${_nbsp}330');
    expect(formatKm(12480), '12${_nbsp}480');
    expect(formatKm(1234567), '1${_nbsp}234${_nbsp}567');
  });

  testWidgets('shows km, the move and the last moves', (tester) async {
    await pumpLayout(tester);
    expect(tester.takeException(), isNull);

    expect(find.text(t.route.letterCaption), findsNothing);
    expect(
      find.bySemanticsLabel(RegExp(t.route.letterCaption)),
      findsOneWidget,
    );
    expect(
      find.text('12${_nbsp}480$_nbsp${t.route.km}', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.text('10${_nbsp}950$_nbsp${t.route.km}', findRichText: true),
      findsOneWidget,
    );
    expect(find.text(t.route.move(n: 9, total: 15)), findsOneWidget);

    // Six rows, the newest on top
    expect(find.text('+2${_nbsp}330$_nbsp${t.route.km}'), findsOneWidget);
    expect(find.text(t.route.skipped), findsOneWidget);
    final kadis = tester.getRect(find.text('Кадис', findRichText: true));
    final skip = tester.getRect(find.text(t.route.skipped));
    final lubek = tester.getRect(find.text('Любек', findRichText: true));
    expect(kadis.top, lessThan(skip.top));
    expect(skip.top, lessThan(lubek.top));
    expect(find.text('Казань', findRichText: true), findsOneWidget);
    expect(find.text('Архангельск', findRichText: true), findsNothing);

    expect(
      find.bySemanticsLabel(t.route.mapLabel(n: 15, city: 'Кадис')),
      findsOneWidget,
    );
  });

  testWidgets('fits 320px at 1.3 text scale with the keyboard open', (
    tester,
  ) async {
    await pumpLayout(
      tester,
      size: const Size(320, 640),
      textScale: 1.3,
      keyboard: 280,
    );
    expect(tester.takeException(), isNull);
    expect(find.text(t.route.move(n: 9, total: 15)), findsOneWidget);

    events.add(const Corrections({'сочи', 'самара'}));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1500));
    expect(tester.takeException(), isNull);
    // The corrections stay above the keyboard of 280 on the 640 screen
    expect(tester.getRect(find.text('Самара')).bottom, lessThanOrEqualTo(360));
  });

  testWidgets('handoff in the route shows km and the move', (tester) async {
    await tester.pumpWidget(
      withTranslations(
        MaterialApp(
          theme: buildAppTheme(Brightness.light),
          home: Scaffold(
            body: HotseatTurnView(
              activeIndex: 1,
              players: const [
                HotseatPlayer(name: 'Аня', score: 12480),
                HotseatPlayer(name: 'Боря', score: 900),
              ],
              letter: 'к',
              timeLimit: 60,
              routeMove: 3,
              onBack: () {},
              onReady: () {},
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('12${_nbsp}480$_nbsp${t.route.km}'), findsOneWidget);
    expect(find.text('900$_nbsp${t.route.km}'), findsOneWidget);
    expect(find.text(t.route.move(n: 3, total: 15)), findsOneWidget);
  });
}
