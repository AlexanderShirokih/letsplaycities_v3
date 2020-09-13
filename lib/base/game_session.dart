import 'dart:async';

import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/game/game_mode.dart';
import 'package:lets_play_cities/base/game/player/surrender_exception.dart';
import 'package:lets_play_cities/base/users.dart';
import 'package:lets_play_cities/base/game/management.dart';
import 'package:lets_play_cities/utils/string_utils.dart';
import 'package:lets_play_cities/utils/stream_utils.dart';
import 'package:meta/meta.dart';

class GameSession {
  /// Game participants
  final UsersList usersList;

  /// Current game mode
  final GameMode mode;

  /// An event channel for passing events to handlers
  final AbstractEventChannel eventChannel;

  /// Time limit in seconds per users move
  final int timeLimit;

  final _inputEvents = StreamController<GameEvent>.broadcast();
  final _disconnectionEvents = StreamController<OnMoveFinished>.broadcast();

  bool _gameRunning = true;

  /// Stream containing all events
  Stream<GameEvent> get inputEvents => _inputEvents.stream;

  /// Stream containing all users word checking results
  Stream<WordCheckingResult> get wordCheckingResults => _inputEvents.stream
      .where((event) => event is WordCheckingResult)
      .cast<WordCheckingResult>();

  GameSession(
      {@required this.mode,
      @required this.usersList,
      @required this.eventChannel,
      @required this.timeLimit})
      : assert(usersList != null),
        assert(eventChannel != null),
        assert(timeLimit != null) {
    inputEvents.listen((event) {
      //TODO: Debug print
      print("EVENT=$event");
    });
  }

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

  /// Finishes current game and surrenders the player if it current user now
  void surrender() {
    _gameRunning = false;
    _disconnectionEvents.add(
      OnMoveFinished(usersList.currentPlayer == null
          ? MoveFinishType.Disconnected
          : MoveFinishType.Surrender),
    );
  }

  /// Runs game processing loop
  Future runMoves() => _runMoves().pipe(_inputEvents);

  Stream<GameEvent> _runMoves() async* {
    // Await for UI to built
    // otherwise we can lose first [OnUserSwitchedEvent] in UI layer
    await Future.delayed(Duration(milliseconds: 150));

    while (_gameRunning) {
      yield* mergeByShortest([
        _createTimer(),
        _makeMoveForCurrentUser(),
        _disconnectionEvents.stream
      ]).takeWhile((element) {
        final isMoveFinished = element is OnMoveFinished;
        if (isMoveFinished &&
            (element as OnMoveFinished).endType != MoveFinishType.Completed)
          _gameRunning = false;
        return !isMoveFinished;
      });
    }
  }

  /// Starts game turn for current user.
  Stream<GameEvent> _makeMoveForCurrentUser() async* {
    var lastSuitableChar = _lastAcceptedWord.isEmpty
        ? ""
        : _lastAcceptedWord[indexOfLastSuitableChar(_lastAcceptedWord)];
    final currentUser = usersList.current;

    // Send current user switching event
    yield* eventChannel
        .sendEvent(OnUserSwitchedEvent(currentUser, usersList.all));

    // Update the first char
    yield* eventChannel.sendEvent(OnFirstCharChanged(lastSuitableChar));

    while (_gameRunning) {
      String city;
      try {
        city = await currentUser.onCreateWord(lastSuitableChar);
      } on SurrenderException {
        yield OnMoveFinished(MoveFinishType.Surrender);
        return;
      }

      final results = eventChannel.sendEvent(RawWordEvent(city, currentUser));
      await for (final event in results) {
        yield event;
        if (event is Accepted) {
          _lastAcceptedWord = event.word;
          usersList.switchToNext();
          return;
        }
      }
    }
  }

  Stream<GameEvent> _createTimer() async* {
    if (timeLimit == 0) return;
    yield* Stream.periodic(
            const Duration(seconds: 1), (tick) => timeLimit - tick)
        .map((currentTime) => TimeEvent(formatTime(currentTime)))
        .take(timeLimit + 1)
        .takeWhile((_) => _gameRunning);

    yield OnMoveFinished(MoveFinishType.Timeout);
  }

  Future cancel() async {
    _gameRunning = false;
    await _disconnectionEvents.close();
    await _inputEvents.close();
  }
}
