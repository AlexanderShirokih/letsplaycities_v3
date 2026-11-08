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

Player _player(String name) => Player(
  LocalAccountInfo(name: name, picture: const PlaceholderPictureSource()),
);

/// A game of two players on one device that waits for [gate] before a move.
GameSession _gatedSession(
  TurnGate gate, {
  required AbstractEventChannel channel,
  int timeLimit = 0,
}) => GameSession(
  mode: GameMode.playerVsPlayer,
  usersList: UsersList([_player('first'), _player('second')]),
  eventChannel: channel,
  scoringType: ScoringType.byScore,
  timeLimit: timeLimit,
  scoreController: ScoreController(
    ScoringSet.initial(),
    ScoringType.byScore,
    GameMode.playerVsPlayer,
    (_) {},
  ),
  achievements: _RecordingAchievements(),
  wordsDifficulty: () => Difficulty.easy,
  turnGate: gate,
);

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
      scoreController: ScoreController(
        ScoringSet.initial(),
        ScoringType.byScore,
        GameMode.playerVsPlayer,
        (_) {},
      ),
      achievements: _RecordingAchievements(),
      wordsDifficulty: () => Difficulty.easy,
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
      scoreController: ScoreController(
        ScoringSet.initial(),
        ScoringType.byScore,
        GameMode.playerVsAndroid,
        (_) {},
      ),
      achievements: achievements,
      wordsDifficulty: () {
        difficultyReads++;
        return difficulty;
      },
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
}
