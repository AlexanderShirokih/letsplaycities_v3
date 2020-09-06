import 'dart:async';

import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/game/player/surrender_exception.dart';
import 'package:lets_play_cities/base/users.dart';
import 'package:lets_play_cities/base/game/management.dart';
import 'package:lets_play_cities/utils/string_utils.dart';
import 'package:lets_play_cities/utils/stream_utils.dart';
import 'package:meta/meta.dart';

class GameSession {
  /// Game participants
  final UsersList usersList;

  /// An event channel for passing events to handlers
  final AbstractEventChannel eventChannel;

  /// Time limit in seconds per users move
  final int timeLimit;

  final _inputEvents = StreamController<GameEvent>.broadcast();

  bool _gameRunning = true;

  /// Stream containing all events
  Stream<GameEvent> get inputEvents => _inputEvents.stream;

  /// Stream containing all users word checking results
  Stream<WordCheckingResult> get wordCheckingResults => _inputEvents.stream
      .where((event) => event is WordCheckingResult)
      .cast<WordCheckingResult>();

  GameSession(
      {@required this.usersList,
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

  /// Runs game processing loop
  Future runMoves() async {
    print("Await!");
    await _runMoves().pipe(_inputEvents);
    print("Awaited!");
  }

  Stream<GameEvent> _runMoves() async* {
    while (_gameRunning) {
      yield* mergeByShortest([
        _createTimer(),
        _makeMoveForCurrentUser(),
      ]).takeWhile((element) {
        final isMoveFinished = element is OnMoveFinished;

        if (isMoveFinished &&
            (element as OnMoveFinished).endType != MoveFinishType.Completed) {
          _gameRunning = false;
        }
        return !isMoveFinished;
      });

      usersList.switchToNext();
    }
  }

  /// Starts game turn for current user.
  Stream<GameEvent> _makeMoveForCurrentUser() async* {
    var lastSuitableChar = _lastAcceptedWord.isEmpty
        ? ""
        : _lastAcceptedWord[indexOfLastSuitableChar(_lastAcceptedWord)];
    final currentUser = usersList.current;

    // Send current user switching event
    yield* eventChannel.sendEvent(OnUserSwitchedEvent(currentUser));

    // Update the first char
    yield* eventChannel.sendEvent(OnFirstCharChanged(lastSuitableChar));

    final startTime = DateTime.now().millisecondsSinceEpoch;

    while (_gameRunning) {
      String city;
      try {
        city = await currentUser.onCreateWord(lastSuitableChar);
      } on SurrenderException {
        yield OnMoveFinished(0, MoveFinishType.Surrender);
        return;
      }

      final results = eventChannel.sendEvent(RawWordEvent(city, currentUser));

      await for (final event in results) {
        yield event;
        if (event is Accepted) {
          _lastAcceptedWord = event.word;

          final now = DateTime.now().millisecondsSinceEpoch;

          // Finish move by yielding a finish event
          yield OnMoveFinished(
              (now - startTime) ~/ 1000, MoveFinishType.Completed);
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
        .take(timeLimit + 1);
    yield OnMoveFinished(timeLimit, MoveFinishType.Timeout);
  }

  Future cancel() async {
    _gameRunning = false;

    await _inputEvents.close();
  }
}
