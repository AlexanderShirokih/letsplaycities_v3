import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/achievements/achievements.dart';
import 'package:lets_play_cities/base/achievements/achievements_service.dart';
import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/dictionary.dart';
import 'package:lets_play_cities/base/game/combo.dart';
import 'package:lets_play_cities/base/game/game_mode.dart';
import 'package:lets_play_cities/base/game/management.dart';
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

void main() {
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
