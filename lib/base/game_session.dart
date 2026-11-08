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

  /// `true` when a server judges the moves and ends the game. The timer then
  /// only shows the time, and only the server ends the game: by timeout, by
  /// surrender or when a player leaves.
  final bool serverAuthoritative;

  /// How long a surrender waits for the server to end the game before the
  /// game ends here
  static const leaveTimeout = Duration(seconds: 3);

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

  /// Ends the game here when the server does not answer a surrender
  Timer? _leaveFallback;

  /// Completes when the last service event has passed the event channel
  Future<void> _serviceEventsSent = Future.value();

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
    this.serverAuthoritative = false,
  }) {
    scoreController.onMoveCombos = _summary.onCombos;
    _externalEvents = externalEvents;
  }

  /// Events from outside the game, such as the server; read once the game
  /// loop listens, so that the events the source keeps until then are not
  /// lost
  Stream<GameEvent> Function(GameSession)? _externalEvents;

  /// The end of the game that came from outside. It ends the game even if
  /// it came while no move listened to the service events.
  OnMoveFinished? _externalFinish;

  void _listenToExternalEvents() {
    final externalEvents = _externalEvents;
    if (externalEvents == null || !_gameRunning) return;

    _externalEvents = null;
    unawaited(
      externalEvents(this).asyncMap((event) async {
        if (!_gameRunning) return;

        if (event is OnMoveFinished &&
            event.endType != MoveFinishType.completed) {
          _externalFinish ??= event;
        }

        await _sendServiceEvent(event);
      }).drain(),
    );
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

  /// Sends service event to _serviceEvents pipe. Events pass the channel one
  /// after another: a stream cannot be added while another one is.
  Future _sendServiceEvent(GameEvent event) {
    final sent = _serviceEventsSent.then((_) async {
      if (_serviceEvents.isClosed) return;

      await _serviceEvents.addStream(eventChannel.sendEvent(event));
    });
    _serviceEventsSent = sent.catchError((_) {});

    return sent;
  }

  /// Finishes the current game and surrenders the player
  /// if it is a current user now.
  /// On server authority the server is asked to end the game instead: see
  /// [leaveTimeout].
  Future surrender() async {
    if (serverAuthoritative) return _leave();

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

  /// Asks the server to end the game with the loss of the player. The game
  /// ends with the answer of the server, or here as a surrender after
  /// [leaveTimeout].
  Future<void> _leave() async {
    if (!_gameRunning || _leaveFallback != null) return;

    final owner = usersList.all.firstWhere((user) => user is Player);
    _leaveFallback = Timer(leaveTimeout, () {
      if (!_gameRunning) return;

      _gameRunning = false;
      _sendServiceEvent(OnMoveFinished(MoveFinishType.surrender, owner));
    });

    await _sendServiceEvent(LeaveRequested(owner));
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
      _leaveFallback?.cancel();
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
        serverAuthoritative: serverAuthoritative,
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

    _listenToExternalEvents();

    while (_gameRunning) {
      final externalFinish = _externalFinish;
      if (externalFinish != null) {
        _gameRunning = false;
        yield externalFinish;
        return;
      }

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

    // On server authority only the server ends a move that ran out of time
    if (!serverAuthoritative) {
      yield OnMoveFinished(MoveFinishType.timeout, usersList.current);
    }
  }

  Future cancel() async {
    _gameRunning = false;
    _leaveFallback?.cancel();
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
