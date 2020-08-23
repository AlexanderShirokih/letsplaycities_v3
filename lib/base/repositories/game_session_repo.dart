import 'dart:async';

import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/game/word_checking_result.dart';
import 'package:lets_play_cities/base/repos.dart';
import 'package:lets_play_cities/base/users.dart';
import 'package:lets_play_cities/base/management.dart';
import 'package:lets_play_cities/base/game_session.dart';
import 'package:lets_play_cities/base/game/game_facade.dart';
import 'package:lets_play_cities/utils/debouncer.dart';

class GameSessionRepository {
  final Debouncer _userInputDebounce =
      Debouncer(const Duration(milliseconds: 1000));
  final StreamController<WordCheckingResult> _wordCheckingResults =
      StreamController.broadcast();

  GameSession _session;

  GameSessionRepository(GameFacade gameFacade) {
    final usersList = UsersList([
      Player(
        gameFacade,
        PlayerData(
          name: "Игрок",
          picture: PlaceholderPictureSource(),
        ),
      ),
      Android(gameFacade, "Андроид"),
    ]);

    _session = GameSession(
      usersList: usersList,
      eventChannel: StubEventChannel(usersList),
    );
  }

  Stream<WordCheckingResult> get wordCheckingResults =>
      _wordCheckingResults.stream;

  /// Creates new instance of [GameItemsRepository]
  GameItemsRepository createGameItemsRepository() =>
      GameItemsRepository(_session);

  /// Creates new instance of [GameServiceEventsRepository]
  GameServiceEventsRepository createGameServiceEventsRepository() =>
      GameServiceEventsRepository(_session);

  /// Returns a user attached to the [position].
  User getUserByPosition(Position position) =>
      _session.getUserByPosition(position);

  /// Called when the game starts
  void start() => _session.start();

  /// Called to dispose internal StreamControllers
  void dispose() {
    _wordCheckingResults.close();
    _userInputDebounce.cancel();
  }

  /// Dispatches input word to the game session
  void sendInputWord(String input) {
    _userInputDebounce.run(() {
      _wordCheckingResults.sink.addStream(_session.deliverUserInput((input)));
    });
  }
}
