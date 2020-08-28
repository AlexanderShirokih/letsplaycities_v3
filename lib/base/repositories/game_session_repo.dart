import 'dart:async';

import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/repos.dart';
import 'package:lets_play_cities/base/users.dart';
import 'package:lets_play_cities/base/dictionary.dart';
import 'package:lets_play_cities/base/game_session.dart';
import 'package:lets_play_cities/base/game/handlers.dart';
import 'package:lets_play_cities/base/game/management.dart';
import 'package:lets_play_cities/utils/debouncer.dart';

class GameSessionRepository {
  final Debouncer _userInputDebounce =
      Debouncer(const Duration(milliseconds: 1000));

  GameSession _session;

  GameSessionRepository(DictionaryProxy dictionary) {
    final usersList = UsersList([
      Player(
        PlayerData(
          name: "Игрок",
          picture: PlaceholderPictureSource(),
        ),
      ),
      Android(dictionary, "Андроид"),
    ]);

    final localGameProcessors = [
      FirstLetterChecker(),
      ExclusionsChecker(ExclusionsService()),
      DatabaseChecker(dictionary),
    ];

    _session = GameSession(
      usersList: usersList,
      eventChannel: ProcessingEventChannel(localGameProcessors),
      timeLimit: 92
    );
  }

  Stream<WordCheckingResult> get wordCheckingResults =>
      _session.wordCheckingResults;

  /// Creates new instance of [GameItemsRepository]
  GameItemsRepository createGameItemsRepository() =>
      GameItemsRepository(_session.inputEvents);

  /// Creates new instance of [GameServiceEventsRepository]
  GameServiceEventsRepository createGameServiceEventsRepository() =>
      GameServiceEventsRepository(_session.inputEvents);

  /// Returns a user attached to the [position].
  User getUserByPosition(Position position) =>
      _session.getUserByPosition(position);

  /// Called to dispose internal StreamControllers
  void dispose() {
    _userInputDebounce.cancel();
    _session.cancel();
  }

  /// Runs moves loop
  Future run() => _session.runMoves();

  /// Dispatches input word to the game session
  void sendInputWord(String input) {
    _userInputDebounce.run(() => _session.deliverUserInput((input)));
  }
}
