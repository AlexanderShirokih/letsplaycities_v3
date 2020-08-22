import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/dictionary.dart';
import 'package:lets_play_cities/base/management.dart';
import 'package:lets_play_cities/base/game/game_facade.dart';
import 'package:lets_play_cities/base/repositories/game_items_repo.dart';
import 'package:lets_play_cities/base/game_session.dart';
import 'package:lets_play_cities/base/users.dart';

import '../preferences.dart';

class GameSessionRepository {
  static GameFacade gameFacade = new GameFacade(
      ExclusionsService(), DictionaryService(), GamePreferences());

  GameSession _session;

  GameSessionRepository()
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

  /// Returns a user attached to the [position].
  User getUserByPosition(Position position) =>
      _session.getUserByPosition(position);
}
