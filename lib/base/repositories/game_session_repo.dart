import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/management.dart';
import 'package:lets_play_cities/base/game/game_facade.dart';
import 'package:lets_play_cities/base/repositories/game_items_repo.dart';
import 'package:lets_play_cities/base/game_session.dart';
import 'package:lets_play_cities/base/repositories/game_service_events.dart';
import 'package:lets_play_cities/base/users.dart';

class GameSessionRepository {
  GameSession _session;

  GameSessionRepository(GameFacade gameFacade)
      : _session = GameSession(
          users: [
            Player(
              gameFacade,
              PlayerData(
                name: "Игрок",
                picture: PlaceholderPictureSource(),
              ),
            ),
            Android(gameFacade, "Андроид"),
          ],
          eventChannel: StubEventChannel(),
        );

  /// Creates new instance of [GameItemsRepository]
  GameItemsRepository createGameItemsRepository() =>
      GameItemsRepository(_session);

  /// Creates new instance of [GameServiceEventsRepository]
  GameServiceEventsRepository createGameServiceEventsRepository() =>
      GameServiceEventsRepository(_session);

  /// Returns a user attached to the [position].
  User getUserByPosition(Position position) =>
      _session.getUserByPosition(position);
}
