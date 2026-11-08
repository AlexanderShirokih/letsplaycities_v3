import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/game/game_result.dart';
import 'package:lets_play_cities/base/game/management.dart';
import 'package:lets_play_cities/base/scoring.dart';
import 'package:lets_play_cities/base/users.dart';

import 'player/fakes.dart';

/// A game between the owner and an opponent with the given scores, finished
/// while it is [ownersTurn] or the opponent's turn.
GameResult _finish({
  required ScoringType scoringType,
  required MoveFinishType finishType,
  int ownerScore = 0,
  int opponentScore = 0,
  bool ownersTurn = true,
}) {
  final owner = createPlayer('owner')..increaseScore(ownerScore);
  final opponent = createPlayer('opponent')..increaseScore(opponentScore);
  final users = UsersList([owner, opponent]);
  if (!ownersTurn) users.switchToNext();

  return GameResultChecker(
    users: users,
    owner: owner,
    finishType: finishType,
    scoringType: scoringType,
    finishRequester: users.current,
  ).getGameResults();
}

void main() {
  group('LAST_MOVE', () {
    test('the user who could not answer loses', () {
      for (final finishType in [
        MoveFinishType.surrender,
        MoveFinishType.timeout,
      ]) {
        expect(
          _finish(
            scoringType: ScoringType.lastMove,
            finishType: finishType,
            ownersTurn: true,
          ).matchResult,
          MatchResult.lose,
          reason: '$finishType',
        );
        expect(
          _finish(
            scoringType: ScoringType.lastMove,
            finishType: finishType,
            ownersTurn: false,
          ).matchResult,
          MatchResult.win,
          reason: '$finishType',
        );
      }
    });

    test('has no score', () {
      final result = _finish(
        scoringType: ScoringType.lastMove,
        finishType: MoveFinishType.surrender,
      );

      expect(result.hasScore, isFalse);
    });
  });

  for (final scoringType in [ScoringType.byScore, ScoringType.byTime]) {
    group('$scoringType', () {
      MatchResult resultFor(int ownerScore, int opponentScore) => _finish(
        scoringType: scoringType,
        finishType: MoveFinishType.surrender,
        ownerScore: ownerScore,
        opponentScore: opponentScore,
      ).matchResult;

      test('the user with more points wins', () {
        expect(resultFor(30, 20), MatchResult.win);
        expect(resultFor(20, 30), MatchResult.lose);
      });

      test('equal points are a draw', () {
        expect(resultFor(25, 25), MatchResult.draw);
        expect(resultFor(0, 0), MatchResult.draw);
      });

      test('the owner who surrenders with more points still wins', () {
        final result = _finish(
          scoringType: scoringType,
          finishType: MoveFinishType.surrender,
          ownerScore: 30,
          opponentScore: 20,
          ownersTurn: true,
        );

        expect(result.matchResult, MatchResult.win);
        expect(result.finishRequester, same(result.owner));
      });

      test('a timeout is judged by the last move, not by points', () {
        expect(
          _finish(
            scoringType: scoringType,
            finishType: MoveFinishType.timeout,
            ownerScore: 30,
            opponentScore: 20,
            ownersTurn: true,
          ).matchResult,
          MatchResult.lose,
        );
        expect(
          _finish(
            scoringType: scoringType,
            finishType: MoveFinishType.timeout,
            ownerScore: 20,
            opponentScore: 30,
            ownersTurn: false,
          ).matchResult,
          MatchResult.win,
        );
      });

      test('has score', () {
        final result = _finish(
          scoringType: scoringType,
          finishType: MoveFinishType.timeout,
        );

        expect(result.hasScore, isTrue);
        expect(result.finishType, MoveFinishType.timeout);
      });
    });
  }

  group('server authority', () {
    /// The result of a network game that the server ended with [loser]
    /// losing; the scores and the turn play no part.
    MatchResult resultWhenLoses({
      required bool ownerLoses,
      required MoveFinishType finishType,
      required ScoringType scoringType,
    }) {
      final owner = createPlayer('owner')..increaseScore(ownerLoses ? 50 : 0);
      final opponent = createPlayer('opponent')
        ..increaseScore(ownerLoses ? 0 : 50);
      final users = UsersList([owner, opponent]);
      if (ownerLoses) users.switchToNext();

      return GameResultChecker(
        users: users,
        owner: owner,
        finishType: finishType,
        scoringType: scoringType,
        finishRequester: ownerLoses ? owner : opponent,
        serverAuthoritative: true,
      ).getGameResults().matchResult;
    }

    test('loser decides result regardless of score', () {
      for (final scoringType in ScoringType.values) {
        for (final finishType in [
          MoveFinishType.surrender,
          MoveFinishType.timeout,
          MoveFinishType.disconnected,
        ]) {
          final reason = '$scoringType, $finishType';

          expect(
            resultWhenLoses(
              ownerLoses: true,
              finishType: finishType,
              scoringType: scoringType,
            ),
            MatchResult.lose,
            reason: reason,
          );
          expect(
            resultWhenLoses(
              ownerLoses: false,
              finishType: finishType,
              scoringType: scoringType,
            ),
            MatchResult.win,
            reason: reason,
          );
        }
      }
    });
  });
}
