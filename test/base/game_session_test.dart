import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/achievements/achievements.dart';
import 'package:lets_play_cities/base/achievements/achievements_service.dart';
import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/dictionary.dart';
import 'package:lets_play_cities/base/game/combo.dart';
import 'package:lets_play_cities/base/game/game_mode.dart';
import 'package:lets_play_cities/base/game/game_result.dart';
import 'package:lets_play_cities/base/game/management.dart';
import 'package:lets_play_cities/base/game/player/surrender_exception.dart';
import 'package:lets_play_cities/base/game/rules/classic_rules.dart';
import 'package:lets_play_cities/base/game/turn_gate.dart';
import 'package:lets_play_cities/base/game_session.dart';
import 'package:lets_play_cities/base/scoring.dart';
import 'package:lets_play_cities/base/users.dart';

class _RecordingChannel extends AbstractEventChannel {
  final sent = <GameEvent>[];

  @override
  Stream<GameEvent> sendEvent(GameEvent event) {
    sent.add(event);
    return Stream.value(event);
  }
}

/// Accepts every word, as the checks of a real game accept a valid city.
class _AcceptingChannel extends AbstractEventChannel {
  @override
  Stream<GameEvent> sendEvent(GameEvent event) => Stream.value(
    event is RawWordEvent
        ? Accepted(event.word, event.owner, status: CityStatus.ok)
        : event,
  );
}

class _RecordingAchievements extends Fake implements AchievementsService {
  final unlocked = <Achievement>[];
  final submittedScores = <int>[];

  @override
  Future<void> unlockAchievement(
    Achievement achievement, [
    int incrementCount = 1,
  ]) async => unlocked.add(achievement);

  @override
  Future<void> submitScore(int score) async => submittedScores.add(score);
}

/// Fails on its first move and never answers after that.
class _BrokenUser extends User {
  int moves = 0;

  _BrokenUser()
    : super(
        accountInfo: const LocalAccountInfo(
          name: 'broken',
          picture: PlaceholderPictureSource(),
        ),
        comboSystem: ComboSystem(canUseQuickTime: false),
        isTrusted: false,
      );

  @override
  Future<String> onCreateWord(String firstChar) {
    moves++;
    return moves == 1
        ? Future.error(StateError('broken move'))
        : Completer<String>().future;
  }
}

/// Accepts every word, like the checks and the server; holds back leave
/// requests, which the network interceptor turns into `leave`.
class _ServerChannel extends AbstractEventChannel {
  final leaves = <LeaveRequested>[];

  /// When `true`, the ends of the game stay in the channel and never come out
  bool holdFinishes = false;

  @override
  Stream<GameEvent> sendEvent(GameEvent event) {
    if (event is LeaveRequested) {
      leaves.add(event);

      return const Stream.empty();
    }

    if (holdFinishes &&
        event is OnMoveFinished &&
        event.endType != MoveFinishType.completed) {
      return StreamController<GameEvent>().stream;
    }

    return Stream.value(
      event is RawWordEvent
          ? Accepted(event.word, event.owner, status: CityStatus.ok)
          : event,
    );
  }
}

/// The opponent of a network game: its words are the ones the test sends.
class _OpponentUser extends User {
  final words = StreamController<String>();
  late final _queue = StreamIterator(words.stream);

  _OpponentUser()
    : super(
        accountInfo: const LocalAccountInfo(
          name: 'opponent',
          picture: PlaceholderPictureSource(),
        ),
        comboSystem: ComboSystem(canUseQuickTime: false),
        isTrusted: true,
      );

  @override
  Future<String> onCreateWord(String firstChar) async {
    await _queue.moveNext();

    return _queue.current;
  }
}

/// A game on server authority between [owner] and [opponent]; [server] plays
/// the events that come from the game server.
class _ServerGame {
  final owner = _player('owner');
  final opponent = _OpponentUser();
  final channel = _ServerChannel();
  final server = StreamController<GameEvent>();
  late final GameSession session;

  _ServerGame({required int timeLimit, bool ownerStarts = true}) {
    final scores = ScoreController(
      ScoringSet.initial(),
      ScoringType.byScore,
      GameMode.network,
      (_) {},
    );

    session = GameSession(
      mode: GameMode.network,
      usersList: UsersList(ownerStarts ? [owner, opponent] : [opponent, owner]),
      eventChannel: channel,
      scoringType: ScoringType.byScore,
      timeLimit: timeLimit,
      scoreController: scores,
      achievements: _RecordingAchievements(),
      wordsDifficulty: () => Difficulty.easy,
      rules: ClassicRules(scores),
      externalEvents: (_) => server.stream,
      serverAuthoritative: true,
    );
  }
}

Player _player(String name) => Player(
  LocalAccountInfo(name: name, picture: const PlaceholderPictureSource()),
);

/// A game of two players on one device that waits for [gate] before a move.
GameSession _gatedSession(
  TurnGate gate, {
  required AbstractEventChannel channel,
  int timeLimit = 0,
}) {
  final scores = ScoreController(
    ScoringSet.initial(),
    ScoringType.byScore,
    GameMode.playerVsPlayer,
    (_) {},
  );

  return GameSession(
    mode: GameMode.playerVsPlayer,
    usersList: UsersList([_player('first'), _player('second')]),
    eventChannel: channel,
    scoringType: ScoringType.byScore,
    timeLimit: timeLimit,
    scoreController: scores,
    achievements: _RecordingAchievements(),
    wordsDifficulty: () => Difficulty.easy,
    rules: ClassicRules(scores),
    turnGate: gate,
  );
}

void main() {
  test('timer does not tick while gate is closed', () {
    fakeAsync((async) {
      final gate = TurnGate();
      final session = _gatedSession(
        gate,
        channel: _RecordingChannel(),
        timeLimit: 5,
      );
      final events = <GameEvent>[];
      session.inputEvents.listen(events.add);
      session.runMoves().ignore();

      async.elapse(const Duration(seconds: 3));

      expect(gate.waiting.value, isNotNull);
      expect(events.whereType<TimeEvent>(), isEmpty);
      expect(events.whereType<OnUserSwitchedEvent>(), isEmpty);

      gate.release();
      async.elapse(const Duration(seconds: 2));

      expect(events.whereType<TimeEvent>(), isNotEmpty);

      session.cancel();
      async.flushTimers();
    });
  });

  test('double release starts one move in the game', () {
    fakeAsync((async) {
      final gate = TurnGate();
      final channel = _RecordingChannel();
      final session = _gatedSession(gate, channel: channel);
      session.runMoves().ignore();
      async.elapse(const Duration(milliseconds: 200));

      gate
        ..release()
        ..release();
      async.flushMicrotasks();

      expect(channel.sent.whereType<OnUserSwitchedEvent>().length, 1);
      expect(gate.waiting.value, isNull);

      session.cancel();
      async.flushTimers();
    });
  });

  test('after an accepted move the gate waits for the second player', () {
    fakeAsync((async) {
      final gate = TurnGate();
      final session = _gatedSession(gate, channel: _AcceptingChannel());
      final [first, second] = session.usersList.all;
      session.runMoves().ignore();
      async.elapse(const Duration(milliseconds: 200));

      expect(gate.waiting.value, same(first));

      gate.release();
      async.flushMicrotasks();
      session.deliverUserInput('москва');
      async.flushMicrotasks();

      expect(session.lastAcceptedWord, 'москва');
      expect(gate.waiting.value, same(second));

      session.cancel();
      async.flushTimers();
    });
  });

  test('results carry summary', () {
    fakeAsync((async) {
      final gate = TurnGate();
      final session = _gatedSession(gate, channel: _AcceptingChannel());
      final [first, _] = session.usersList.all;
      GameResult? result;
      session.runMoves().then((value) => result = value);
      async.elapse(const Duration(milliseconds: 200));

      // The handoff before the first move is not part of the game.
      async.elapse(const Duration(seconds: 30));

      for (final city in ['москва', 'анапа', 'амстердам']) {
        gate.release();
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 10));
        session.deliverUserInput(city);
        async.flushMicrotasks();
      }

      session.scoreController.onMoveFinished(first, 'москва', 1000, {
        ComboType.quickTime.index: 2,
      });
      session.surrender();
      async.flushMicrotasks();

      expect(result!.summary.citiesCount, 3);
      expect(result!.summary.duration, const Duration(seconds: 30));
      expect(result!.summary.longestCity?.city, 'амстердам');
      expect(result!.summary.bestCombos, {ComboType.quickTime: 2});
    });
  });

  test('cancel while the gate is closed ends the game without a move', () {
    fakeAsync((async) {
      final gate = TurnGate();
      final channel = _RecordingChannel();
      final session = _gatedSession(gate, channel: channel);
      Object? error;
      var finished = false;
      session.runMoves().then<void>(
        (_) => finished = true,
        onError: (Object e) => error = e,
      );
      async.elapse(const Duration(milliseconds: 200));
      expect(gate.waiting.value, isNotNull);

      session.cancel();
      async.flushMicrotasks();

      expect(error, isNull);
      expect(finished, isTrue);
      expect(channel.sent.whereType<OnUserSwitchedEvent>(), isEmpty);
    });
  });

  testWidgets('ends the game loop with the error of a move', (tester) async {
    final channel = _RecordingChannel();
    final user = _BrokenUser();
    final scores = ScoreController(
      ScoringSet.initial(),
      ScoringType.byScore,
      GameMode.playerVsPlayer,
      (_) {},
    );
    final session = GameSession(
      mode: GameMode.playerVsPlayer,
      usersList: UsersList([
        user,
        Player(
          const LocalAccountInfo(
            name: 'player',
            picture: PlaceholderPictureSource(),
          ),
        ),
      ]),
      eventChannel: channel,
      scoringType: ScoringType.byScore,
      timeLimit: 0,
      scoreController: scores,
      achievements: _RecordingAchievements(),
      wordsDifficulty: () => Difficulty.easy,
      rules: ClassicRules(scores),
    );
    var inputClosed = false;
    session.inputEvents.listen(null, onDone: () => inputClosed = true);

    Object? error;
    unawaited(session.runMoves().then<void>((_) {}, onError: (e) => error = e));
    // Fake time covers the start delay of the game loop.
    await tester.pump(const Duration(milliseconds: 200));
    // Under fake async the error only arrives after one turn of the real
    // event loop.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();

    expect(error, isA<StateError>());
    expect(inputClosed, isTrue);
    // No further move was started after the failed one.
    expect(user.moves, 1);
    expect(channel.sent.whereType<OnUserSwitchedEvent>().length, 1);
  });

  testWidgets('reports achievements with the difficulty set at game end', (
    tester,
  ) async {
    final achievements = _RecordingAchievements();
    var difficulty = Difficulty.easy;
    var difficultyReads = 0;
    final player = Player(
      const LocalAccountInfo(
        name: 'player',
        picture: PlaceholderPictureSource(),
      ),
    );
    final scores = ScoreController(
      ScoringSet.initial(),
      ScoringType.byScore,
      GameMode.playerVsAndroid,
      (_) {},
    );
    final session = GameSession(
      mode: GameMode.playerVsAndroid,
      usersList: UsersList([
        player,
        Player(
          const LocalAccountInfo(
            name: 'second',
            picture: PlaceholderPictureSource(),
          ),
        ),
      ]),
      eventChannel: _RecordingChannel(),
      scoringType: ScoringType.byScore,
      timeLimit: 0,
      scoreController: scores,
      achievements: achievements,
      wordsDifficulty: () {
        difficultyReads++;
        return difficulty;
      },
      rules: ClassicRules(scores),
    );
    player.increaseScore(10);

    var finished = false;
    unawaited(session.runMoves().then((_) => finished = true));
    // Fake time covers the start delay of the game loop.
    await tester.pump(const Duration(milliseconds: 200));
    expect(difficultyReads, 0);

    difficulty = Difficulty.hard;
    await session.surrender();
    await tester.pump();

    expect(finished, isTrue);
    expect(difficultyReads, 1);
    expect(achievements.unlocked, contains(Achievement.playInHardMode));
    expect(achievements.submittedScores, [10]);
  });

  group('server authority', () {
    testWidgets('server game ignores local timeout', (tester) async {
      final game = _ServerGame(timeLimit: 3);
      final events = <GameEvent>[];
      game.session.inputEvents.listen(events.add);
      var finished = false;
      unawaited(game.session.runMoves().then((_) => finished = true));
      // Fake time covers the start delay of the game loop.
      await tester.pump(const Duration(milliseconds: 200));

      for (var second = 0; second < 10; second++) {
        await tester.pump(const Duration(seconds: 1));
      }
      // Under fake async the end of the timer only arrives after one turn of
      // the real event loop.
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();

      expect(events.whereType<TimeEvent>().last.secondsLeft, 0);
      expect(events.whereType<OnMoveFinished>(), isEmpty);
      expect(finished, isFalse);

      await game.session.cancel();
    });

    test('timer restarts on opponent accepted word', () {
      fakeAsync((async) {
        final game = _ServerGame(timeLimit: 10, ownerStarts: false);
        final events = <GameEvent>[];
        game.session.inputEvents.listen(events.add);
        game.session.runMoves().ignore();
        async.elapse(const Duration(milliseconds: 200));

        async.elapse(const Duration(seconds: 6));
        expect(events.whereType<TimeEvent>().last.secondsLeft, 5);

        game.opponent.words.add('москва');
        async.flushMicrotasks();
        events.clear();
        async.elapse(const Duration(seconds: 1));

        expect(events.whereType<TimeEvent>().map((e) => e.secondsLeft), [10]);

        game.session.cancel();
        async.flushTimers();
      });
    });

    test('timer restarts on own accepted word', () {
      fakeAsync((async) {
        final game = _ServerGame(timeLimit: 10);
        final events = <GameEvent>[];
        game.session.inputEvents.listen(events.add);
        game.session.runMoves().ignore();
        async.elapse(const Duration(milliseconds: 200));

        async.elapse(const Duration(seconds: 6));
        expect(events.whereType<TimeEvent>().last.secondsLeft, 5);

        game.session.deliverUserInput('москва');
        async.flushMicrotasks();
        events.clear();
        async.elapse(const Duration(seconds: 1));

        expect(events.whereType<TimeEvent>().map((e) => e.secondsLeft), [10]);

        game.session.cancel();
        async.flushTimers();
      });
    });

    test('fallback surrender is not lost when a move ends first', () {
      fakeAsync((async) {
        final game = _ServerGame(timeLimit: 0, ownerStarts: false);
        GameResult? result;
        Object? error;
        game.session.runMoves().then<void>(
          (value) => result = value,
          onError: (Object e) => error = e,
        );
        async.elapse(const Duration(milliseconds: 200));

        game.channel.holdFinishes = true;
        game.session.surrender();
        async.elapse(const Duration(milliseconds: 3100));

        // The opponent's word ends the move while the fallback is on its way
        game.opponent.words.add('москва');
        async.flushMicrotasks();

        expect(error, isNull);
        expect(result!.finishType, MoveFinishType.surrender);
        expect(result!.finishRequester, same(game.owner));
        expect(result!.matchResult, MatchResult.lose);
      });
    });

    test('a gameOver after the fallback ends nothing twice', () {
      fakeAsync((async) {
        final game = _ServerGame(timeLimit: 0);
        final finishes = <OnMoveFinished>[];
        game.session.inputEvents.listen((event) {
          if (event is OnMoveFinished) finishes.add(event);
        });
        GameResult? result;
        game.session.runMoves().then((value) => result = value);
        async.elapse(const Duration(milliseconds: 200));

        game.session.surrender();
        async.elapse(const Duration(milliseconds: 3100));
        expect(result!.finishRequester, same(game.owner));

        game.server.add(
          OnMoveFinished(MoveFinishType.surrender, game.opponent),
        );
        async.elapse(const Duration(seconds: 1));

        expect(finishes, hasLength(1));
        expect(result!.matchResult, MatchResult.lose);
      });
    });

    test('a surrender names the user it gives up for', () {
      fakeAsync((async) {
        final game = _ServerGame(timeLimit: 0, ownerStarts: false);
        GameResult? result;
        game.session.runMoves().then((value) => result = value);
        async.elapse(const Duration(milliseconds: 200));

        // The owner leaves while the opponent moves
        game.opponent.words.addError(SurrenderException(game.owner, true));
        async.flushMicrotasks();

        expect(result!.finishType, MoveFinishType.surrender);
        expect(result!.finishRequester, same(game.owner));
        expect(result!.matchResult, MatchResult.lose);
      });
    });

    test('server events before the game loop starts are not lost', () {
      fakeAsync((async) {
        final game = _ServerGame(timeLimit: 0);
        final messages = <MessageEvent>[];
        game.session.inputEvents.listen((event) {
          if (event is MessageEvent) messages.add(event);
        });

        // The opponent greets and leaves while the game screen loads
        game.server
          ..add(MessageEvent('привет', game.opponent))
          ..add(OnMoveFinished(MoveFinishType.disconnected, game.opponent));
        async.elapse(const Duration(seconds: 1));

        GameResult? result;
        game.session.runMoves().then((value) => result = value);
        async.elapse(const Duration(seconds: 1));

        expect(messages.single.message, 'привет');
        expect(result!.finishType, MoveFinishType.disconnected);
        expect(result!.matchResult, MatchResult.win);
      });
    });

    test('surrender sends leave and ends on gameOver', () {
      fakeAsync((async) {
        final game = _ServerGame(timeLimit: 0);
        GameResult? result;
        game.session.runMoves().then((value) => result = value);
        async.elapse(const Duration(milliseconds: 200));
        game.opponent.increaseScore(5);

        game.session.surrender();
        async.flushMicrotasks();

        expect(game.channel.leaves.single.owner, same(game.owner));
        expect(result, isNull);

        game.server.add(OnMoveFinished(MoveFinishType.surrender, game.owner));
        async.flushMicrotasks();

        expect(result!.finishType, MoveFinishType.surrender);
        expect(result!.finishRequester, same(game.owner));
        expect(result!.matchResult, MatchResult.lose);

        async.elapse(const Duration(seconds: 5));
        expect(game.channel.leaves, hasLength(1));
      });
    });

    test('surrender ends locally after 3 s without gameOver', () {
      fakeAsync((async) {
        final game = _ServerGame(timeLimit: 0);
        GameResult? result;
        game.session.runMoves().then((value) => result = value);
        async.elapse(const Duration(milliseconds: 200));
        game.owner.increaseScore(50);

        game.session.surrender();
        async.elapse(const Duration(milliseconds: 2900));
        expect(result, isNull);

        async.elapse(const Duration(milliseconds: 200));

        expect(result!.finishType, MoveFinishType.surrender);
        expect(result!.finishRequester, same(game.owner));
        expect(result!.matchResult, MatchResult.lose);
      });
    });
  });
}
