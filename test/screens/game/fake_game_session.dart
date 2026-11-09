import 'package:lets_play_cities/base/achievements/achievements_service.dart';
import 'package:lets_play_cities/base/dictionary.dart';
import 'package:lets_play_cities/base/game/game_mode.dart';
import 'package:lets_play_cities/base/game/rules/classic_rules.dart';
import 'package:lets_play_cities/base/game/rules/match_rules.dart';
import 'package:lets_play_cities/base/game/management.dart';
import 'package:lets_play_cities/base/game_session.dart';
import 'package:lets_play_cities/base/scoring.dart';
import 'package:lets_play_cities/base/users.dart';

class _PassThroughChannel extends AbstractEventChannel {
  @override
  Stream<GameEvent> sendEvent(GameEvent event) => Stream.value(event);
}

/// A session whose events come from the test instead of the game loop.
class FakeGameSession extends GameSession {
  final Stream<GameEvent> _events;

  FakeGameSession(
    this._events,
    UsersList users, {
    super.mode = GameMode.playerVsPlayer,
    super.timeLimit = 0,
    MatchRules? rules,
  }) : super(
         usersList: users,
         eventChannel: _PassThroughChannel(),
         scoringType: ScoringType.byScore,
         scoreController: ScoreController(
           ScoringSet.initial(),
           ScoringType.byScore,
           mode,
           (_) {},
         ),
         achievements: StubAchievementsService(),
         wordsDifficulty: () => Difficulty.easy,
         rules:
             rules ??
             ClassicRules(
               ScoreController(
                 ScoringSet.initial(),
                 ScoringType.byScore,
                 mode,
                 (_) {},
               ),
               ScoringType.byScore,
             ),
       );

  @override
  Stream<GameEvent> get inputEvents => _events;

  @override
  Stream<WordCheckingResult> get wordCheckingResults =>
      _events.where((event) => event is WordCheckingResult).cast();
}
