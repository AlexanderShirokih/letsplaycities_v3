import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/achievements/achievements_service.dart';
import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/dictionary.dart';
import 'package:lets_play_cities/base/game/game_mode.dart';
import 'package:lets_play_cities/base/game/management.dart';
import 'package:lets_play_cities/base/game_session.dart';
import 'package:lets_play_cities/base/repos.dart';
import 'package:lets_play_cities/base/scoring.dart';
import 'package:lets_play_cities/base/users.dart';

class _PassThroughChannel extends AbstractEventChannel {
  @override
  Stream<GameEvent> sendEvent(GameEvent event) => Stream.value(event);
}

GameSession _session() => GameSession(
  mode: GameMode.playerVsPlayer,
  usersList: UsersList([
    for (final name in ['first', 'second'])
      Player(
        LocalAccountInfo(name: name, picture: const PlaceholderPictureSource()),
      ),
  ]),
  eventChannel: _PassThroughChannel(),
  scoringType: ScoringType.byScore,
  timeLimit: 0,
  scoreController: ScoreController(
    ScoringSet.initial(),
    ScoringType.byScore,
    GameMode.playerVsPlayer,
    (_) {},
  ),
  achievements: StubAchievementsService(),
  wordsDifficulty: () => Difficulty.easy,
);

void main() {
  test('keeps one game items repository per session', () {
    final repository = GameSessionRepository(_session());

    expect(
      identical(
        repository.createGameItemsRepository(),
        repository.createGameItemsRepository(),
      ),
      isTrue,
    );
    expect(
      identical(
        repository.gameItemsRepository,
        repository.createGameItemsRepository(),
      ),
      isTrue,
    );
  });
}
