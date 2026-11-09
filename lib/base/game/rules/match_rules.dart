import 'package:lets_play_cities/base/game/game_result.dart';
import 'package:lets_play_cities/base/game/game_summary.dart';
import 'package:lets_play_cities/base/game/management.dart';
import 'package:lets_play_cities/base/users.dart';

/// What happens when the time of a move runs out
enum TimeoutAction {
  /// The user whose time ran out loses the game
  endGame,

  /// The move passes to the next user and the game goes on
  skip,
}

/// The rules of a match: what a move brings, how a move that ran out of time
/// ends, when the match is over and who wins it.
abstract class MatchRules {
  /// Called for every word of [owner] accepted in [moveTimeMs] from the
  /// start of the move. [activeCombos] maps combo type indexes to levels.
  void onAccepted(
    User owner,
    String word,
    int countryCode,
    int moveTimeMs,
    Map<int, int> activeCombos,
  );

  /// Decides how the move of [user] ends when its time runs out
  TimeoutAction onTimeout(User user);

  /// Called when the move of [user] was skipped
  void onSkipped(User user);

  /// `true` when the match is over after the last finished move
  bool get isOver;

  /// `true` when the match counts for the stats and the achievements
  bool get countsStats;

  /// The result of the match ended by [finish], relative to [owner]
  GameResult result({
    required UsersList users,
    required User owner,
    required OnMoveFinished finish,
    required GameSummary summary,
    required bool serverAuthoritative,
  });
}
