import 'package:equatable/equatable.dart';
import 'package:lets_play_cities/base/game/management.dart';
import 'package:lets_play_cities/base/scoring.dart';
import 'package:lets_play_cities/base/users.dart';

/// Contains data about game finish reason and checks the winner.
class GameResultChecker {
  /// Game finish reason
  final MoveFinishType finishType;

  /// The game scoring mode
  final ScoringType scoringType;

  /// The game users list
  final UsersList users;

  /// User who's responsible for finishing the game
  final User finishRequester;

  /// Main game actor (relative to user's perspective)
  final User owner;

  const GameResultChecker({
    required this.users,
    required this.owner,
    required this.finishType,
    required this.scoringType,
    required this.finishRequester,
  });

  /// Determines game results relative to [owner].
  /// Returns new [GameResult] instance with game results
  GameResult getGameResults() => GameResult(
    owner: owner,
    finishType: finishType,
    hasScore: scoringType != ScoringType.lastMove,
    matchResult: _getMatchResult(
      finishType == MoveFinishType.timeout ? ScoringType.lastMove : scoringType,
    ),
    finishRequester: finishRequester,
  );

  MatchResult _getMatchResult(ScoringType scoringType) =>
      scoringType == ScoringType.lastMove
      // Wins user that have the last completed move
      ? users.current == owner
            ? MatchResult.lose
            : MatchResult.win
      // Wins user that have more score points at the end
      : _getMathResultByScore();

  MatchResult _getMathResultByScore() =>
      (users.all.every((user) => user.score == owner.score))
      ? MatchResult.draw
      : (owner ==
                users.all.reduce(
                  (value, element) =>
                      value.score > element.score ? value : element,
                )
            ? MatchResult.win
            : MatchResult.lose);
}

/// Describes game result for specific user
enum MatchResult {
  /// The user wins the game
  win,

  /// The user loses the game
  lose,

  /// Game result for the user is draw
  draw,
}

/// Contains game result relative to owner
class GameResult extends Equatable {
  /// Game main actor (relative to user's perspective)
  final User owner;

  /// Game result (relative to [owner])
  final MatchResult matchResult;

  /// Game finish reason
  final MoveFinishType finishType;

  /// Does [owner] has score
  final bool hasScore;

  /// User who's responsible for finishing the game
  final User finishRequester;

  const GameResult({
    required this.owner,
    required this.matchResult,
    required this.finishType,
    required this.hasScore,
    required this.finishRequester,
  });

  @override
  List<Object?> get props => [
    owner,
    matchResult,
    finishType,
    hasScore,
    finishRequester,
  ];
}
