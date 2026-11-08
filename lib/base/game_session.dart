import 'dart:async';

import 'package:clock/clock.dart';
import 'package:lets_play_cities/base/achievements/achievements.dart';
import 'package:lets_play_cities/base/achievements/achievements_service.dart';
import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/dictionary.dart';
import 'package:lets_play_cities/base/game/game_mode.dart';
import 'package:lets_play_cities/base/game/game_result.dart';
import 'package:lets_play_cities/base/game/game_summary.dart';
import 'package:lets_play_cities/base/game/management.dart';
import 'package:lets_play_cities/base/game/player/surrender_exception.dart';
import 'package:lets_play_cities/base/game/turn_gate.dart';
import 'package:lets_play_cities/base/scoring.dart';
import 'package:lets_play_cities/base/users.dart';
import 'package:lets_play_cities/utils/stream_utils.dart';
import 'package:lets_play_cities/utils/string_utils.dart';

class GameSession {
  /// Game participants
  final UsersList usersList;

  /// Current game mode
  final GameMode mode;

  /// Current scoring type mode
  final ScoringType scoringType;

  /// Game scoring service
  final ScoreController scoreController;

  /// An event channel for passing events to handlers
  final AbstractEventChannel eventChannel;

  /// Time limit in seconds per users move
  final int timeLimit;

  /// Holds every move until the next player is ready, `null` when the game
  /// does not wait
  final TurnGate? turnGate;

  final AchievementsService _achievements;

  /// Called when the game ends, so the setting in effect at that moment counts
  final Difficulty Function() _wordsDifficulty;

  final GameSummaryBuilder _summary = GameSummaryBuilder(clock);

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
    required this.scoreController,
    required this._achievements,
    required this._wordsDifficulty,
    Stream<GameEvent> Function(GameSession)? externalEvents,
    this.turnGate,
  }) {
    scoreController.onMoveCombos = _summary.onCombos;

    if (externalEvents != null) {
      unawaited(
        externalEvents(this).asyncMap((event) async {
          if (_gameRunning) {
            await _sendServiceEvent(event);
          }
        }).drain(),
      );
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
    final currentPlayer =
        usersList.currentPlayer ??
        usersList.all.firstWhere((element) => element is Player);

    _sendServiceEvent(MessageEvent(message, currentPlayer));
  }

  /// Sends service event to _serviceEvents pipe
  Future _sendServiceEvent(GameEvent event) async {
    await _serviceEvents.addStream(eventChannel.sendEvent(event));
  }

  /// Finishes the current game and surrenders the player
  /// if it is a current user now.
  Future surrender() async {
    _gameRunning = false;
    turnGate?.cancel();

    await _sendServiceEvent(
      OnMoveFinished(
        usersList.currentPlayer == null
            ? MoveFinishType.disconnected
            : MoveFinishType.surrender,
        usersList.currentPlayer ??
            usersList.all.firstWhere((user) => user is Player),
      ),
    );
  }

  /// Runs game processing loop
  /// When the game finishes returns [GameResult]
  Future<GameResult> runMoves() async {
    GameEvent? event;
    try {
      await for (event in _runMoves()) {
        _inputEvents.sink.add(event);
      }
    } finally {
      await _inputEvents.close();
    }

    if (event is OnMoveFinished) {
      if (event.endType == MoveFinishType.completed) {
        throw ('This move type should not finish the game!');
      }

      final summary = _summary.build();

      // Update achievements
      await _updateAchievements();

      final gameResults = GameResultChecker(
        users: usersList,
        owner: usersList.all.whereType<Player>().first,
        scoringType: scoringType,
        finishType: event.endType,
        finishRequester: event.finishRequester,
        summary: summary,
      ).getGameResults();

      scoreController.onGameFinished(gameResults);
      scoreController.commit();

      return gameResults;
    }

    throw ('Game has finished without ending with [OnMoveFinished] event');
  }

  Stream<GameEvent> _runMoves() async* {
    // Await for UI to built
    // otherwise we can lose first [OnUserSwitchedEvent] in UI layer
    await Future.delayed(Duration(milliseconds: 150));

    while (_gameRunning) {
      final gate = turnGate;
      if (gate != null) {
        await gate.waitFor(usersList.current);

        // Cancelled while waiting: the waiting player leaves the game, as
        // when the input of a move is closed.
        if (!_gameRunning) {
          yield OnMoveFinished(MoveFinishType.surrender, usersList.current);
          return;
        }
      }

      _summary.start();

      yield* mergeStreamsWhile(
        [_createTimer(), _makeMoveForCurrentUser(), _serviceEvents.stream],
        (element) {
          final isMoveFinished = element is OnMoveFinished;
          if (element is OnMoveFinished &&
              element.endType != MoveFinishType.completed) {
            _gameRunning = false;
          }
          return !isMoveFinished;
        },
      );
    }
  }

  /// Starts game turn for current user.
  Stream<GameEvent> _makeMoveForCurrentUser() async* {
    final lastSuitableChar = findLastSuitableChar(_lastAcceptedWord);
    final currentUser = usersList.current;

    // Send current user switching event
    yield* eventChannel.sendEvent(
      OnUserSwitchedEvent(currentUser, usersList.all),
    );

    // Update the first char
    yield* eventChannel.sendEvent(OnFirstCharChanged(lastSuitableChar));

    while (_gameRunning) {
      String city;
      try {
        city = await currentUser.onCreateWord(lastSuitableChar);
      } on SurrenderException {
        yield OnMoveFinished(MoveFinishType.surrender, currentUser);
        return;
      }

      final results = eventChannel.sendEvent(RawWordEvent(city, currentUser));
      await for (final event in results) {
        yield event;
        if (event is Accepted) {
          if (event.owner is Player) _playerMovesInGame++;
          _summary.onAccepted(event.owner, event.word, event.countryCode ?? 0);

          _lastAcceptedWord = event.word;
          usersList.switchToNext();
          yield OnMoveFinished(MoveFinishType.completed, currentUser);
          return;
        }
      }
    }
  }

  Stream<GameEvent> _createTimer() async* {
    if (timeLimit == 0) return;
    yield* Stream.periodic(
          const Duration(seconds: 1),
          (tick) => timeLimit - tick,
        )
        .map((secondsLeft) => TimeEvent(secondsLeft))
        .take(timeLimit + 1)
        .takeWhile((_) => _gameRunning);

    yield OnMoveFinished(MoveFinishType.timeout, usersList.current);
  }

  Future cancel() async {
    _gameRunning = false;
    turnGate?.cancel();

    await usersList.close();
    await _serviceEvents.close();
  }

  // Checks for achievements type when game ends
  Future<void> _updateAchievements() async {
    final playerScore = usersList.all.whereType<Player>().first.score;

    final nonEmptyScore = playerScore > 0;

    if (nonEmptyScore) {
      await _achievements.unlockAchievement(
        Achievement.write15Cities,
        _playerMovesInGame,
      );
      await _achievements.unlockAchievement(
        Achievement.write80Cities,
        _playerMovesInGame,
      );
      await _achievements.unlockAchievement(
        Achievement.write500Cities,
        _playerMovesInGame,
      );
      await _achievements.unlockAchievement(
        Achievement.reachScore1000Pts,
        playerScore,
      );
      await _achievements.unlockAchievement(
        Achievement.reachScore5000Pts,
        playerScore,
      );
      await _achievements.unlockAchievement(
        Achievement.reachScore25000Pts,
        playerScore,
      );

      if (_playerMovesInGame >= 50) {
        await _achievements.unlockAchievement(Achievement.write50CitiesInGame);
      }
      if (_playerMovesInGame >= 100) {
        await _achievements.unlockAchievement(Achievement.write100CitiesInGame);
      }

      final difficulty = _wordsDifficulty();

      if (difficulty == Difficulty.hard) {
        await _achievements.unlockAchievement(Achievement.playInHardMode);
      }
      if (mode == GameMode.network) {
        await _achievements.unlockAchievement(Achievement.playOnline3Times);
      }
      if (mode != GameMode.playerVsPlayer) {
        await _achievements.submitScore(playerScore);
      }
    }
  }
}
