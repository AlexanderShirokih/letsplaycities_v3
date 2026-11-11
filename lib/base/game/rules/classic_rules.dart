import 'package:lets_play_cities/base/game/game_result.dart';
import 'package:lets_play_cities/base/game/game_summary.dart';
import 'package:lets_play_cities/base/game/management.dart';
import 'package:lets_play_cities/base/game/rules/match_rules.dart';
import 'package:lets_play_cities/base/scoring.dart';
import 'package:lets_play_cities/base/users.dart';

/// The classic match: words bring points through [ScoreController], a move
/// that ran out of time ends the game, and the game goes on until someone
/// leaves it.
class ClassicRules implements MatchRules {
  final ScoreController _scoreController;

  ClassicRules(this._scoreController);

  @override
  void onAccepted(
    User owner,
    String word,
    int countryCode,
    int moveTimeMs,
    Map<int, int> activeCombos,
  ) => _scoreController.onMoveFinished(owner, word, moveTimeMs, activeCombos);

  @override
  TimeoutAction onTimeout(User user) => TimeoutAction.endGame;

  @override
  void onSkipped(User user) {}

  @override
  bool get isOver => false;

  @override
  bool get countsStats => true;

  @override
  GameResult result({
    required UsersList users,
    required User owner,
    required OnMoveFinished finish,
    required GameSummary summary,
    required bool serverAuthoritative,
  }) => GameResultChecker(
    users: users,
    owner: owner,
    finishType: finish.endType,
    finishRequester: finish.finishRequester,
    summary: summary,
    serverAuthoritative: serverAuthoritative,
  ).getGameResults();
}
