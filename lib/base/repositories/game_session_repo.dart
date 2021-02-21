import 'dart:async';

import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/game/game_mode.dart';
import 'package:lets_play_cities/base/game/game_result.dart';
import 'package:lets_play_cities/base/game/management.dart';
import 'package:lets_play_cities/base/game_session.dart';
import 'package:lets_play_cities/base/repos.dart';
import 'package:lets_play_cities/base/users.dart';
import 'package:lets_play_cities/utils/debouncer.dart';

class GameSessionRepository {
  final Debouncer _userInputDebounce =
      Debouncer(const Duration(milliseconds: 1000));

  final GameSession _session;

  GameSessionRepository(this._session);

  Stream<WordCheckingResult> get wordCheckingResults =>
      _session.wordCheckingResults;

  /// `true` if this game mode supports players help
  bool get helpAvailable => _session.mode == GameMode.playerVsAndroid;

  /// `true` if this game mode supports messaging
  bool get messagingAvailable =>
      _session.mode == GameMode.network &&
      _session.usersList.all.every((user) => user.isMessagesAllowed);

  /// Returns latest accepted word
  String get lastAcceptedWord => _session.lastAcceptedWord;

  /// Creates new instance of [GameItemsRepository]
  GameItemsRepository createGameItemsRepository() =>
      GameItemsRepository(_session.inputEvents);

  /// Creates new instance of [GameServiceEventsRepository]
  GameServiceEventsRepository createGameServiceEventsRepository() =>
      GameServiceEventsRepository(_session.inputEvents);

  /// Returns a user attached to the [position].
  User getUserByPosition(Position position) =>
      _session.getUserByPosition(position);

  /// Finished the game and surrenders current player
  Future surrender() => _session.surrender();

  /// Called to dispose internal StreamControllers
  Future finish() async {
    _userInputDebounce.cancel();
    await _session.cancel();
  }

  /// Runs moves loop
  /// When the game finishes returns [GameResult]
  Future<GameResult> run() => _session.runMoves();

  /// Dispatches input word to the game session
  void sendInputWord(String input) {
    _userInputDebounce.run(() => _session.deliverUserInput(input));
  }

  /// Dispatches input message to the game session
  void sendChatMessage(String message) {
    _userInputDebounce.run(() => _session.deliverUserMessage(message));
  }
}
