import 'dart:async';

import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/game/management.dart';
import 'package:lets_play_cities/base/users.dart';
import 'package:lets_play_cities/utils/string_utils.dart';
import 'package:meta/meta.dart';

class GameSession {
  final UsersList usersList;
  final AbstractEventChannel eventChannel;
  final _inputEvents = StreamController<GameEvent>.broadcast();

  bool _gameRunning = true;

  /// Stream containing all events
  Stream<GameEvent> get inputEvents => _inputEvents.stream;

  /// Stream containing all users word checking results
  Stream<WordCheckingResult> get wordCheckingResults => _inputEvents.stream
      .where((event) => event is WordCheckingResult)
      .cast<WordCheckingResult>();

  GameSession({@required this.usersList, @required this.eventChannel})
      : assert(usersList != null),
        assert(eventChannel != null);

  /// Returns user attached to the [position]
  /// Throws [StateError] if there is no user attached to the [position].
  User getUserByPosition(Position position) =>
      usersList.getUserByPosition(position);

  /// Last accepted word
  String _lastAcceptedWord = "";

  /// Dispatches user input to the current [Player] in users list
  void deliverUserInput(String userInput) {
    usersList.currentPlayer?.onUserInput(userInput);
  }

  /// Runs game processing loop
  Future runMoves() async {
    await _runMoves().pipe(_inputEvents);
  }

  Stream<GameEvent> _runMoves() async* {
    yield OnUserSwitchedEvent(usersList.first);

    while (_gameRunning) {
      yield* _makeMoveForCurrentUser();
      usersList.switchToNext();

      yield OnUserSwitchedEvent(usersList.current);
    }
  }

  /// Starts game turn for current user.
  Stream<GameEvent> _makeMoveForCurrentUser() async* {
    var lastSuitableChar = _lastAcceptedWord.isEmpty
        ? ""
        : _lastAcceptedWord[indexOfLastSuitableChar(_lastAcceptedWord)];

    final currentUser = usersList.current;
    final city = await currentUser.onCreateWord(lastSuitableChar);

    // Update the first char
    yield await eventChannel
        .sendEvent(OnFirstCharChanged(lastSuitableChar))
        .drain();

    final results = eventChannel.sendEvent(RawWordEvent(city, currentUser));

    await for (final event in results) {
      if (event is Accepted) {
        _lastAcceptedWord = event.word;
      }
      yield event;
    }
  }

  Future cancel() async {
    _gameRunning = false;
    await _inputEvents.close();
  }
}
