import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/game/game_result.dart';
import 'package:lets_play_cities/base/game/management.dart';
import 'package:lets_play_cities/base/users.dart';

import 'player/fakes.dart';

/// A game between the owner and an opponent with the given scores, finished
/// by the user whose turn it is: the owner when [ownersTurn].
GameResult _finish({
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
    finishRequester: users.current,
  ).getGameResults();
}

void main() {
  group('surrender', () {
    test('the user who surrenders loses whatever the points', () {
      final result = _finish(
        finishType: MoveFinishType.surrender,
        ownerScore: 30,
        opponentScore: 20,
        ownersTurn: true,
      );

      expect(result.matchResult, MatchResult.lose);
      expect(result.finishRequester, same(result.owner));
    });

    test('the opponent who surrenders loses whatever the points', () {
      expect(
        _finish(
          finishType: MoveFinishType.surrender,
          ownerScore: 20,
          opponentScore: 30,
          ownersTurn: false,
        ).matchResult,
        MatchResult.win,
      );
    });
  });

  group('timeout', () {
    test('the user whose time ran out loses whatever the points', () {
      expect(
        _finish(
          finishType: MoveFinishType.timeout,
          ownerScore: 30,
          opponentScore: 20,
          ownersTurn: true,
        ).matchResult,
        MatchResult.lose,
      );
      expect(
        _finish(
          finishType: MoveFinishType.timeout,
          ownerScore: 20,
          opponentScore: 30,
          ownersTurn: false,
        ).matchResult,
        MatchResult.win,
      );
    });
  });

  group('disconnection', () {
    MatchResult resultFor(int ownerScore, int opponentScore) => _finish(
      finishType: MoveFinishType.disconnected,
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
  });

  test('has score', () {
    final result = _finish(finishType: MoveFinishType.timeout);

    expect(result.hasScore, isTrue);
    expect(result.finishType, MoveFinishType.timeout);
  });

  group('server authority', () {
    /// The result of a network game that the server ended with the owner
    /// losing when [ownerLoses]; the scores and the turn play no part.
    MatchResult resultWhenLoses({
      required bool ownerLoses,
      required MoveFinishType finishType,
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
        finishRequester: ownerLoses ? owner : opponent,
        serverAuthoritative: true,
      ).getGameResults().matchResult;
    }

    test('loser decides result regardless of score', () {
      for (final finishType in [
        MoveFinishType.surrender,
        MoveFinishType.timeout,
        MoveFinishType.disconnected,
      ]) {
        expect(
          resultWhenLoses(ownerLoses: true, finishType: finishType),
          MatchResult.lose,
          reason: '$finishType',
        );
        expect(
          resultWhenLoses(ownerLoses: false, finishType: finishType),
          MatchResult.win,
          reason: '$finishType',
        );
      }
    });
  });
}
