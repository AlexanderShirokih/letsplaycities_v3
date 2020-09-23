import 'package:lets_play_cities/base/game/management.dart';
import 'package:lets_play_cities/base/scoring.dart';
import 'package:lets_play_cities/base/users.dart';
import 'package:meta/meta.dart';

/// Contains data about game finish reason and checks the winner.
class GameResultChecker {
  final MoveFinishType finishType;
  final ScoringType scoringType;
  final UsersList users;
  final User owner;

  const GameResultChecker({
    @required this.users,
    @required this.owner,
    @required this.finishType,
    @required this.scoringType,
  });

  /// Determines game results relative to [owner]
  GameResult getGameResults() => GameResult(
        owner: owner,
        finishType: finishType,
        hasScore: scoringType != ScoringType.LAST_MOVE,
        matchResult: _getMatchResult(
          finishType == MoveFinishType.Timeout
              ? ScoringType.LAST_MOVE
              : scoringType,
        ),
      );

  MatchResult _getMatchResult(ScoringType scoringType) =>
      scoringType == ScoringType.LAST_MOVE
          // Wins user that have the last completed move
          ? users.current == owner
              ? MatchResult.LOSE
              : MatchResult.WIN
          // Wins user that have more score points at the end
          : _getMathResultByScore();

  MatchResult _getMathResultByScore() =>
      (users.all.every((user) => user.score == owner.score))
          ? MatchResult.DRAW
          : (owner ==
                  users.all.reduce((value, element) =>
                      value.score > element.score ? value : element)
              ? MatchResult.WIN
              : MatchResult.LOSE);
}

/// Describes game result for specific user
enum MatchResult {
  /// The user wins the game
  WIN,

  /// The user loses the game
  LOSE,

  /// Game result for the user is draw
  DRAW
}

/// Contains game result relative to owner
class GameResult {
  final User owner;
  final MatchResult matchResult;
  final MoveFinishType finishType;
  final bool hasScore;

  const GameResult({
    @required this.owner,
    @required this.matchResult,
    @required this.finishType,
    @required this.hasScore,
  })  : assert(owner != null),
        assert(matchResult != null),
        assert(finishType != null),
        assert(hasScore != null);
}
