import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/achievements/achievements.dart';
import 'package:lets_play_cities/base/achievements/achievements_service.dart';
import 'package:lets_play_cities/base/dictionary.dart';
import 'package:lets_play_cities/base/dictionary/countrycode_overrides.dart';
import 'package:lets_play_cities/base/dictionary/impl/dictionary_impl.dart';
import 'package:lets_play_cities/base/game/game_config.dart';
import 'package:lets_play_cities/base/game/game_mode.dart';
import 'package:lets_play_cities/base/game/game_result.dart';
import 'package:lets_play_cities/base/game/game_session_factory.dart';
import 'package:lets_play_cities/base/game/handlers.dart';
import 'package:lets_play_cities/base/game/management.dart';
import 'package:lets_play_cities/base/game/player/default_player_names.dart';
import 'package:lets_play_cities/base/game/rules/route_rules.dart';
import 'package:lets_play_cities/base/game_session.dart';
import 'package:lets_play_cities/base/geo/route_data.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/base/repositories/game_session_repo.dart';
import 'package:lets_play_cities/base/scoring.dart';
import 'package:lets_play_cities/base/users.dart';

import '../geo/geo_test_data.dart';

class _FakePreferences extends Fake implements GamePreferences {
  @override
  ScoringType scoringType = ScoringType.byScore;

  @override
  int timeLimit = 0;

  @override
  Difficulty wordsDifficulty = Difficulty.easy;

  @override
  bool correctionEnabled = false;
}

class _NoExclusions implements ExclusionsService {
  @override
  String checkForExclusion(String city) => '';

  @override
  String? getAlternativeName(String city) => null;

  @override
  bool hasNoExclusions(String input) => true;
}

class _NoOverrides implements CountryCodeOverrides {
  @override
  int? findOverride(String word) => null;
}

class _RecordingAchievements extends Fake implements AchievementsService {
  final unlocked = <Achievement>[];

  @override
  Future<void> unlockAchievement(
    Achievement achievement, [
    int incrementCount = 1,
  ]) async => unlocked.add(achievement);

  @override
  Future<void> submitScore(int score) async {}
}

/// Holds the checked words before the endpoint until [release]
class _HoldingHandler extends EventHandler {
  final _gate = Completer<void>();

  void release() => _gate.complete();

  @override
  Stream<GameEvent> process(GameEvent event) async* {
    if (event is Accepted || event is NotFound) {
      await _gate.future;
    }

    yield event;
  }
}

const _letters = 'бвгдежзклмн';

/// Cities that begin and end with "а", so that any of them follows any other
final _cities = [
  for (var i = 0; i < 40; i++)
    'а${_letters[i ~/ _letters.length]}${_letters[i % _letters.length]}а',
];

/// A city that ends with a letter no city begins with; only the player knows
/// it, the computer plays easy cities only
const _deadEnd = 'абвг';

class _Game {
  final prefs = _FakePreferences();
  final achievements = _RecordingAchievements();
  late final DictionaryServiceImpl dictionary;
  late final GameSession session;
  late final GameSessionRepository repository;
  final events = <GameEvent>[];
  var commits = 0;
  GameResult? result;

  _Game({
    GameMode mode = GameMode.playerVsAndroid,
    int timeLimit = 0,
    List<EventHandler>? handlers,
  }) {
    prefs.timeLimit = timeLimit;
    dictionary = DictionaryServiceImpl({
      for (final city in _cities)
        city: CityProperties(difficulty: 0, countryCode: 1),
      _deadEnd: CityProperties(difficulty: 2, countryCode: 1),
    });

    final routeData = RouteData(
      dictionary,
      geoIndexOf({
        for (var i = 0; i < _cities.length; i++)
          _cities[i]: (i * 0x9000, i * 0x31000 - 0x400000),
        _deadEnd: (-0x100000, 0x100000),
      }),
      emptyWorld(),
    );

    session = GameSessionFactory.createForGameMode(
      preferences: prefs,
      config: GameConfig(
        gameMode: mode,
        variant: GameVariant.route,
        additionalEventHandlers: handlers,
      ),
      exclusions: _NoExclusions(),
      dictionary: DictionaryDecorator(dictionary, prefs),
      codeOverrides: _NoOverrides(),
      scoreController: ScoreController(
        ScoringSet.initial(),
        ScoringType.byScore,
        mode,
        (_) => commits++,
      ),
      achievements: achievements,
      playerNames: const DefaultPlayerNames(
        player: 'player',
        android: 'android',
        firstPlayer: 'first',
        secondPlayer: 'second',
      ),
      onUserInputAccepted: () {},
      onUserMoveBegins: () {},
      routeData: routeData,
    );
    repository = GameSessionRepository(session, routeData: routeData);
  }

  RouteState get route => repository.routeState!;

  User get first => session.usersList.all.first;

  User get second => session.usersList.all.last;

  /// Starts the game and lets the start delay of the game loop pass
  Future<void> start(WidgetTester tester) async {
    session.inputEvents.listen(events.add);
    // A cancelled game ends with an error, which these tests do not check
    unawaited(
      session.runMoves().then((value) => result = value, onError: (_) {}),
    );
    await _pass(tester, const Duration(milliseconds: 200));
  }

  /// The first city nobody has named yet
  String get freeCity =>
      _cities.firstWhere((c) => !dictionary.getAll()[c]!.used);

  /// The player of the move names [city]
  Future<void> say(WidgetTester tester, String city) async {
    session.deliverUserInput(city);
    await _pass(tester);
  }

  /// Ends the game that is still running
  Future<void> cancel(WidgetTester tester) async {
    await session.cancel();
    await _pass(tester, const Duration(seconds: 3));
  }
}

/// Lets [duration] of the game pass in fake time. The event channel of the
/// game passes events through `asyncExpand`, which under fake time goes on
/// only in turns of the real event loop, so every step gives it some.
Future<void> _pass(
  WidgetTester tester, [
  Duration duration = Duration.zero,
]) async {
  const step = Duration(milliseconds: 500);
  var left = duration;

  while (true) {
    for (var turn = 0; turn < 30; turn++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 1)),
      );
      await tester.pump();
    }

    if (left <= Duration.zero) return;

    final next = left < step ? left : step;
    await tester.pump(next);
    left -= next;
  }
}

void main() {
  testWidgets('a game against the computer ends after 30 moves', (
    tester,
  ) async {
    final game = _Game();
    await game.start(tester);

    for (var round = 0; round < 15; round++) {
      await game.say(tester, game.freeCity);
      // The computer answers after its pause
      await _pass(tester, const Duration(milliseconds: 1500));
    }

    final result = game.result!;
    expect(result.finishType, MoveFinishType.routeCompleted);
    expect(result.route!.movesDone, 30);
    expect(result.route!.legs.where((leg) => leg.skipped), isEmpty);
    expect(game.route.movesOf(game.second), 15);
    expect(game.first.score, greaterThan(0));
    expect(game.second.score, greaterThan(0));
    expect(game.commits, 0);
    expect(game.achievements.unlocked, isEmpty);
  });

  testWidgets('the route states follow the moves', (tester) async {
    final game = _Game();
    final states = <RouteState>[];
    game.repository.routeStates!.listen(states.add);
    await game.start(tester);

    await game.say(tester, _cities[0]);

    expect(states.map((s) => s.movesDone), [0, 1]);
    expect(game.repository.geo![_cities[0]], isNotNull);
    expect(game.repository.world, isNotNull);

    await game.cancel(tester);
  });

  testWidgets('a move that ran out of time is skipped and the game goes on', (
    tester,
  ) async {
    final game = _Game(timeLimit: 1);
    await game.start(tester);

    await _pass(tester, const Duration(seconds: 2));
    await _pass(tester);

    expect(game.events.whereType<MoveSkipped>().single.owner, game.first);
    expect(game.route.legs.single.skipped, isTrue);
    expect(game.session.usersList.current, game.second);
    expect(game.result, isNull);

    // The computer answers in its time
    await _pass(tester, const Duration(milliseconds: 1500));

    expect(game.route.legs.last.owner, game.second);
    expect(game.route.legs.last.skipped, isFalse);
    expect(game.session.usersList.current, game.first);

    await game.cancel(tester);
  });

  testWidgets('the computer without a city skips its move at once', (
    tester,
  ) async {
    final game = _Game();
    await game.start(tester);

    // No time passes: the computer does not wait when it has no city
    await game.say(tester, _deadEnd);

    expect(game.events.whereType<MoveSkipped>().single.owner, game.second);
    expect(game.route.legs.last.skipped, isTrue);
    expect(game.session.usersList.current, game.first);
    expect(game.session.lastAcceptedWord, _deadEnd);
    expect(game.result, isNull);

    await game.cancel(tester);
  });

  testWidgets('a skip as the last move ends the game', (tester) async {
    final game = _Game();
    await game.start(tester);

    for (var round = 0; round < 14; round++) {
      await game.say(tester, game.freeCity);
      await _pass(tester, const Duration(milliseconds: 1500));
    }

    // No time passes: the computer does not wait when it has no city
    await game.say(tester, _deadEnd);

    expect(game.result?.finishType, MoveFinishType.routeCompleted);
    expect(game.result?.route?.movesDone, 30);
    expect(game.result?.route?.legs.last.skipped, isTrue);
  });

  testWidgets('a surrender loses the game', (tester) async {
    final game = _Game();
    await game.start(tester);

    unawaited(game.session.surrender());
    await _pass(tester);

    expect(game.result?.finishType, MoveFinishType.surrender);
    expect(game.result?.matchResult, MatchResult.lose);
  });

  group('a word checked while the time runs out', () {
    testWidgets('is accepted, and the move is not skipped', (tester) async {
      final holding = _HoldingHandler();
      final game = _Game(timeLimit: 1, handlers: [holding]);
      await game.start(tester);

      await game.say(tester, _cities[0]);
      await _pass(tester, const Duration(seconds: 3));
      holding.release();
      await _pass(tester);

      expect(game.events.whereType<MoveSkipped>(), isEmpty);
      expect(game.route.legs.single.city, _cities[0]);
      expect(game.session.lastAcceptedWord, _cities[0]);
      expect(game.dictionary.getAll()[_cities[0]]!.used, isTrue);
      expect(game.session.usersList.current, game.second);

      await game.cancel(tester);
    });

    testWidgets('is rejected, and the move is skipped', (tester) async {
      final holding = _HoldingHandler();
      final game = _Game(timeLimit: 1, handlers: [holding]);
      await game.start(tester);

      await game.say(tester, 'анигде');
      await _pass(tester, const Duration(seconds: 3));
      holding.release();
      await _pass(tester);

      expect(game.events.whereType<MoveSkipped>().single.owner, game.first);
      expect(game.route.legs.single.skipped, isTrue);
      expect(game.session.lastAcceptedWord, isEmpty);
      expect(game.session.usersList.current, game.second);

      await game.cancel(tester);
    });
  });

  group('a game on one phone', () {
    testWidgets('holds the timer until the next player is ready', (
      tester,
    ) async {
      final game = _Game(mode: GameMode.playerVsPlayer, timeLimit: 1);
      final gate = game.session.turnGate!;
      await game.start(tester);

      await _pass(tester, const Duration(seconds: 5));

      expect(gate.waiting.value, game.first);
      expect(game.events.whereType<TimeEvent>(), isEmpty);
      expect(game.route.movesDone, 0);

      gate.release();
      await _pass(tester, const Duration(seconds: 2));
      await _pass(tester);

      expect(game.events.whereType<MoveSkipped>().single.owner, game.first);
      expect(gate.waiting.value, game.second);

      await game.cancel(tester);
    });

    testWidgets('leaving at the gate loses the game for the waiting player', (
      tester,
    ) async {
      final game = _Game(mode: GameMode.playerVsPlayer);
      final gate = game.session.turnGate!;
      await game.start(tester);

      gate.release();
      await _pass(tester);
      await game.say(tester, _cities[0]);
      expect(gate.waiting.value, game.second);

      unawaited(game.session.surrender());
      await _pass(tester);

      expect(game.result?.finishType, MoveFinishType.surrender);
      expect(game.result?.finishRequester, game.second);
      expect(game.result?.matchResult, MatchResult.win);
    });
  });
}
