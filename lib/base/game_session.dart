import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/base/achievements/achievements.dart';
import 'package:lets_play_cities/base/achievements/achievements_service.dart';
import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/dictionary.dart';
import 'package:lets_play_cities/base/game/game_mode.dart';
import 'package:lets_play_cities/base/game/game_result.dart';
import 'package:lets_play_cities/base/game/management.dart';
import 'package:lets_play_cities/base/game/player/surrender_exception.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/base/scoring.dart';
import 'package:lets_play_cities/base/users.dart';
import 'package:lets_play_cities/utils/stream_utils.dart';
import 'package:lets_play_cities/utils/string_utils.dart';
import 'package:pedantic/pedantic.dart';

class GameSession {
  /// Game participants
  final UsersList usersList;

  /// Current game mode
  final GameMode mode;

  /// Current scoring type mode
  final ScoringType scoringType;

  /// An event channel for passing events to handlers
  final AbstractEventChannel eventChannel;

  /// Time limit in seconds per users move
  final int timeLimit;

  // This stream will closed automatically by closing [_serviceEvents]
  // ignore: close_sinks
  final _inputEvents = StreamController<GameEvent>.broadcast();

  /// Stream for sending other event types to _inputEvents through event pipeline.
  /// DON'T send events directly. Use [_sendServiceEvent].
  final _serviceEvents = StreamController<GameEvent>.broadcast();

  bool _gameRunning = true;

  /// Stream containing all events
  Stream<GameEvent> get inputEvents => _inputEvents.stream;

  /// Stream containing all users word checking results
  Stream<WordCheckingResult> get wordCheckingResults => _inputEvents.stream
      .where((event) => event is WordCheckingResult)
      .cast<WordCheckingResult>();

  GameSession({
    required this.mode,
    required this.usersList,
    required this.eventChannel,
    required this.scoringType,
    required this.timeLimit,
    Stream<GameEvent> Function(GameSession)? externalEvents,
  }) {
    if (externalEvents != null) {
      unawaited(externalEvents(this)
          .asyncMap((event) => _sendServiceEvent(event))
          .drain());
    }
  }

  /// Returns user attached to the [position]
  /// Throws [StateError] if there is no user attached to the [position].
  User getUserByPosition(Position position) =>
      usersList.getUserByPosition(position);

  String _lastAcceptedWord = '';
  int _playerMovesInGame = 0;

  /// Last accepted word
  String get lastAcceptedWord => _lastAcceptedWord;

  /// Dispatches user input to the current [Player] in users list
  void deliverUserInput(String userInput) {
    usersList.currentPlayer?.onUserInput(userInput);
  }

  /// Dispatches user input to the current [Player] in users list
  void deliverUserMessage(String message) {
    final currentPlayer = usersList.currentPlayer ??
        usersList.all.firstWhere((element) => element is Player);

    _sendServiceEvent(MessageEvent(message, currentPlayer));
  }

  /// Sends service event to _serviceEvents pipe
  Future _sendServiceEvent(GameEvent event) async {
    if (_gameRunning) {
      await _serviceEvents.addStream(eventChannel.sendEvent(event));
    }
  }

  /// Finishes the current game and surrenders the player
  /// if it is a current user now.
  Future surrender() async {
    _gameRunning = false;
    await _sendServiceEvent(
      OnMoveFinished(
        usersList.currentPlayer == null
            ? MoveFinishType.Disconnected
            : MoveFinishType.Surrender,
        usersList.currentPlayer ??
            usersList.all.firstWhere((user) => user is Player),
      ),
    );
  }

  /// Runs game processing loop
  /// When the game finishes returns [GameResult]
  Future<GameResult> runMoves() async {
    GameEvent? event;
    await for (event in _runMoves()) {
      _inputEvents.sink.add(event);
    }
    await _inputEvents.close();

    if (event is OnMoveFinished) {
      if (event.endType == MoveFinishType.Completed) {
        throw ('This move type should not finish the game!');
      }

      // Update achievements
      await _updateAchievements();

      return GameResultChecker(
        users: usersList,
        owner: usersList.all.whereType<Player>().first,
        scoringType: scoringType,
        finishType: event.endType,
        finishRequester: event.finishRequester,
      ).getGameResults();
    }

    throw ('Game has finished without ending with [OnMoveFinished] event');
  }

  Stream<GameEvent> _runMoves() async* {
    // Await for UI to built
    // otherwise we can lose first [OnUserSwitchedEvent] in UI layer
    await Future.delayed(Duration(milliseconds: 150));

    while (_gameRunning) {
      yield* mergeStreamsWhile([
        _createTimer(),
        _makeMoveForCurrentUser(),
        _serviceEvents.stream,
      ], (element) {
        final isMoveFinished = element is OnMoveFinished;
        if (isMoveFinished &&
            (element as OnMoveFinished).endType != MoveFinishType.Completed) {
          _gameRunning = false;
        }
        return !isMoveFinished;
      });
    }
  }

  /// Starts game turn for current user.
  Stream<GameEvent> _makeMoveForCurrentUser() async* {
    final lastSuitableChar = findLastSuitableChar(_lastAcceptedWord);
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
        yield OnMoveFinished(MoveFinishType.Surrender, currentUser);
        return;
      }

      final results = eventChannel.sendEvent(RawWordEvent(city, currentUser));
      await for (final event in results) {
        yield event;
        if (event is Accepted) {
          if (event.owner is Player) _playerMovesInGame++;

          _lastAcceptedWord = event.word;
          usersList.switchToNext();
          yield OnMoveFinished(MoveFinishType.Completed, currentUser);
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

    yield OnMoveFinished(MoveFinishType.Timeout, usersList.current);
  }

  Future cancel() async {
    _gameRunning = false;

    await usersList.close();
    await _serviceEvents.close();
  }

  // Checks for achievements type when game ends
  Future<void> _updateAchievements() async {
    final achievementService = GetIt.instance.get<AchievementsService>();

    final playerScore = usersList.all.whereType<Player>().first.score;

    final nonEmptyScore = playerScore > 0;

    if (nonEmptyScore) {
      await achievementService.unlockAchievement(
          Achievement.write15Cities, _playerMovesInGame);
      await achievementService.unlockAchievement(
          Achievement.write80Cities, _playerMovesInGame);
      await achievementService.unlockAchievement(
          Achievement.write500Cities, _playerMovesInGame);
      await achievementService.unlockAchievement(
          Achievement.reachScore1000Pts, playerScore);
      await achievementService.unlockAchievement(
          Achievement.reachScore5000Pts, playerScore);
      await achievementService.unlockAchievement(
          Achievement.reachScore25000Pts, playerScore);

      if (_playerMovesInGame >= 50) {
        await achievementService
            .unlockAchievement(Achievement.write50CitiesInGame);
      }
      if (_playerMovesInGame >= 100) {
        await achievementService
            .unlockAchievement(Achievement.write100CitiesInGame);
      }

      final difficulty = GetIt.instance.get<GamePreferences>().wordsDifficulty;

      if (difficulty == Difficulty.HARD) {
        await achievementService.unlockAchievement(Achievement.playInHardMode);
      }
      if (mode == GameMode.Network) {
        await achievementService
            .unlockAchievement(Achievement.playOnline3Times);
      }
      if (mode != GameMode.PlayerVsPlayer) {
        await achievementService.submitScore(playerScore);
      }
    }
  }
}
