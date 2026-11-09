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
import 'package:lets_play_cities/base/game/game_summary.dart';
import 'package:lets_play_cities/base/game/management.dart';
import 'package:lets_play_cities/base/game/rules/match_rules.dart';
import 'package:lets_play_cities/base/game_session.dart';
import 'package:lets_play_cities/base/scoring.dart';
import 'package:lets_play_cities/base/users.dart';

import 'handlers/fake_users.dart';

/// Rules whose decisions the test sets.
class _FakeRules implements MatchRules {
  TimeoutAction timeoutAction = TimeoutAction.endGame;

  /// The match is over after this many accepted words, never when `null`
  int? acceptedToEnd;

  @override
  bool countsStats = true;

  final accepted = <String>[];
  final skipped = <User>[];

  @override
  void onAccepted(
    User owner,
    String word,
    int countryCode,
    int moveTimeMs,
    Map<int, int> activeCombos,
  ) => accepted.add(word);

  @override
  TimeoutAction onTimeout(User user) => timeoutAction;

  @override
  void onSkipped(User user) => skipped.add(user);

  @override
  bool get isOver {
    final toEnd = acceptedToEnd;
    return toEnd != null && accepted.length >= toEnd;
  }

  @override
  GameResult result({
    required UsersList users,
    required User owner,
    required OnMoveFinished finish,
    required GameSummary summary,
    required bool serverAuthoritative,
  }) => GameResult(
    owner: owner,
    matchResult: MatchResult.draw,
    finishType: finish.endType,
    hasScore: true,
    finishRequester: finish.finishRequester,
    summary: summary,
  );
}

/// Accepts every word and gives it to [rules], as the endpoint does; records
/// every event sent.
class _AcceptingChannel extends AbstractEventChannel {
  final _FakeRules rules;
  final sent = <GameEvent>[];

  _AcceptingChannel(this.rules);

  @override
  Stream<GameEvent> sendEvent(GameEvent event) {
    sent.add(event);

    if (event is RawWordEvent) {
      rules.onAccepted(event.owner, event.word, 0, 0, const {});
      return Stream.value(
        Accepted(event.word, event.owner, status: CityStatus.ok),
      );
    }

    return Stream.value(event);
  }
}

/// A user whose words the test gives one by one.
class _ManualUser extends User {
  final moves = <Completer<String>>[];

  _ManualUser(String name)
    : super(
        accountInfo: LocalAccountInfo(
          name: name,
          picture: const PlaceholderPictureSource(),
        ),
        comboSystem: ComboSystem(canUseQuickTime: false),
        isTrusted: true,
      );

  @override
  Future<String> onCreateWord(String firstChar) {
    final move = Completer<String>();
    moves.add(move);

    return move.future;
  }
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

class _Game {
  final rules = _FakeRules();
  final achievements = _RecordingAchievements();
  late final channel = _AcceptingChannel(rules);
  late final GameSession session;
  final events = <GameEvent>[];
  var commits = 0;
  GameResult? result;

  _Game(List<User> users, {int timeLimit = 0}) {
    session = GameSession(
      mode: GameMode.playerVsAndroid,
      usersList: UsersList(users),
      eventChannel: channel,
      scoringType: ScoringType.byScore,
      timeLimit: timeLimit,
      scoreController: ScoreController(
        ScoringSet.initial(),
        ScoringType.byScore,
        GameMode.playerVsAndroid,
        (_) => commits++,
      ),
      achievements: achievements,
      wordsDifficulty: () => Difficulty.easy,
      rules: rules,
    );
  }

  void start() {
    session.inputEvents.listen(events.add);
    session.runMoves().then((value) => result = value);
  }

  /// Starts the game and lets the start delay of the game loop pass.
  void startIn(FakeAsync async) {
    start();
    async.elapse(const Duration(milliseconds: 200));
  }
}

/// Lets [seconds] of the game pass in fake time.
Future<void> pass(WidgetTester tester, int seconds) async {
  for (var second = 0; second < seconds; second++) {
    await tester.pump(const Duration(seconds: 1));
  }

  // Under fake async the end of the timer only arrives after one turn of the
  // real event loop.
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pump();
}

void main() {
  group('a move that ran out of time', () {
    /// Starts [game] and lets [seconds] of the game pass.
    Future<void> play(WidgetTester tester, _Game game, int seconds) async {
      game.start();
      // Fake time covers the start delay of the game loop.
      await tester.pump(const Duration(milliseconds: 200));
      await pass(tester, seconds);
    }

    testWidgets('is skipped when the rules say so and the game goes on', (
      tester,
    ) async {
      final first = _ManualUser('first');
      final second = _ManualUser('second');
      final game = _Game([newPlayer(), first, second], timeLimit: 2);
      game.session.usersList.switchToNext();
      game.rules.timeoutAction = TimeoutAction.skip;
      await play(tester, game, 0);

      first.moves.single.complete('москва');
      await tester.pump();
      expect(game.session.lastAcceptedWord, 'москва');

      await pass(tester, 4);

      expect(game.events.whereType<MoveSkipped>().single.owner, same(second));
      expect(game.rules.skipped, [same(second)]);
      expect(game.session.usersList.current, isA<Player>());
      expect(game.session.lastAcceptedWord, 'москва');
      expect(game.result, isNull);
      expect(game.events.whereType<OnMoveFinished>().map((e) => e.endType), [
        MoveFinishType.completed,
        MoveFinishType.completed,
      ]);

      await game.session.cancel();
    });

    testWidgets('ignores the word its user gives after the skip', (
      tester,
    ) async {
      final first = _ManualUser('first');
      final game = _Game([first, newPlayer()], timeLimit: 2);
      game.rules.timeoutAction = TimeoutAction.skip;
      await play(tester, game, 4);
      expect(game.rules.skipped, [same(first)]);

      first.moves.single.complete('москва');
      await tester.pump();

      expect(game.channel.sent.whereType<RawWordEvent>(), isEmpty);
      expect(game.rules.accepted, isEmpty);
      expect(game.session.lastAcceptedWord, isEmpty);

      await game.session.cancel();
    });

    testWidgets('ends the game when the rules say so', (tester) async {
      final first = _ManualUser('first');
      final game = _Game([first, newPlayer()], timeLimit: 2);
      await play(tester, game, 4);

      expect(game.result?.finishType, MoveFinishType.timeout);
      expect(game.result?.finishRequester, same(first));
      expect(game.events.whereType<MoveSkipped>(), isEmpty);
    });
  });

  test('the game ends when the rules say it is over', () {
    fakeAsync((async) {
      final first = _ManualUser('first');
      final second = _ManualUser('second');
      final game = _Game([newPlayer(), first, second]);
      game.session.usersList.switchToNext();
      game.rules.acceptedToEnd = 2;
      game.startIn(async);

      first.moves.single.complete('москва');
      async.flushMicrotasks();
      expect(game.result, isNull);

      second.moves.single.complete('анапа');
      async.flushMicrotasks();

      expect(game.result?.finishType, MoveFinishType.routeCompleted);
      expect(game.result?.finishRequester, same(second));
      expect(game.rules.accepted, ['москва', 'анапа']);
    });
  });

  group('the end of the game', () {
    /// Plays a game that the player surrenders with some score.
    _Game surrendered(FakeAsync async, {required bool countsStats}) {
      final player = newPlayer()..increaseScore(10);
      final game = _Game([player, FakeOpponent()]);
      game.rules.countsStats = countsStats;
      game.startIn(async);

      game.session.surrender();
      async.flushMicrotasks();

      expect(game.result?.finishType, MoveFinishType.surrender);
      return game;
    }

    test('updates the stats and the achievements when they count', () {
      fakeAsync((async) {
        final game = surrendered(async, countsStats: true);

        expect(game.commits, 1);
        expect(game.achievements.unlocked, isNotEmpty);
      });
    });

    test('leaves the stats and the achievements when they do not count', () {
      fakeAsync((async) {
        final game = surrendered(async, countsStats: false);

        expect(game.commits, 0);
        expect(game.achievements.unlocked, isEmpty);
      });
    });
  });
}
