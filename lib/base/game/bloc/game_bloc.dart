import 'dart:async';

import 'package:clock/clock.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lets_play_cities/base/achievements/achievements.dart';
import 'package:lets_play_cities/base/achievements/achievements_service.dart';
import 'package:lets_play_cities/base/dictionary.dart';
import 'package:lets_play_cities/base/dictionary/countrycode_overrides.dart';
import 'package:lets_play_cities/base/dictionary/exclusion_messages.dart';
import 'package:lets_play_cities/base/dictionary/impl/country_list_loader_factory.dart';
import 'package:lets_play_cities/base/dictionary/impl/dictionary_factory.dart';
import 'package:lets_play_cities/base/dictionary/impl/exclusions_factory.dart';
import 'package:lets_play_cities/base/game/game_result.dart';
import 'package:lets_play_cities/base/game/handlers.dart';
import 'package:lets_play_cities/base/game/player/default_player_names.dart';
import 'package:lets_play_cities/base/game/turn_gate.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/base/repositories/game_session_repo.dart';
import 'package:lets_play_cities/base/scoring.dart';
import 'package:lets_play_cities/remote/dictionary_updater.dart';
import 'package:lets_play_cities/utils/string_utils.dart';
import 'package:meta/meta.dart';

import '../game_config.dart';
import '../game_mode.dart';
import '../game_session_factory.dart';

import 'package:lets_play_cities/base/bloc/sequential_event_mapping.dart';

part 'game_events.dart';

part 'game_states.dart';

/// Used internally when the game loop fails with an error.
class _GameEventRunFailed extends GameStateEvent {
  final Object error;
  final StackTrace stackTrace;

  const _GameEventRunFailed(this.error, this.stackTrace);
}

class GameBloc extends Bloc<GameStateEvent, GameLifecycleState>
    with SequentialEventMapping<GameStateEvent, GameLifecycleState> {
  final GamePreferences _prefs;
  final ExclusionMessages _exclusionMessages;
  final DefaultPlayerNames _playerNames;
  final DictionaryUpdater _dictionaryUpdater;
  final CountryCodeOverrides _codeOverrides;
  final GameConfig _gameConfig;
  final AchievementsService _achievements;

  /// How long the player waits for the next hint
  static const hintCooldown = Duration(minutes: 2);

  OnUserInputAccepted? onUserInputAccepted;
  OnUserMoveBegins? onUserMoveBegins;

  TurnGate? _turnGate;

  /// The gate the running game waits at before each move, `null` before the
  /// game starts and in games that do not wait
  TurnGate? get turnGate => _turnGate;

  @override
  Future<void> close() async {
    if (state is GameState) {
      await (state as GameState).gameSessionRepository.finish();
    }
    return super.close();
  }

  GameBloc({
    required this._gameConfig,
    required this._prefs,
    required this._exclusionMessages,
    required this._playerNames,
    required this._codeOverrides,
    required this._dictionaryUpdater,
    required this._achievements,
  }) : super(InitialState()) {
    mapEventsSequentially(_mapEventToStateSafely);

    add(const GameEventBeginDataLoading());
  }

  Stream<GameLifecycleState> _mapEventToStateSafely(GameStateEvent event) =>
      _mapEventToState(event).transform(
        StreamTransformer.fromHandlers(
          handleError: (
            Object e,
            StackTrace stackTrace,
            EventSink<GameLifecycleState> sink,
          ) => sink.add(ErrorState(e, stackTrace)),
        ),
      );

  Stream<GameLifecycleState> _mapEventToState(GameStateEvent event) async* {
    if (event is GameEventBeginDataLoading) {
      yield* _beginLoading();
    } else if (event is GameEventGameStart) {
      yield* _runGame();
    } else if (event is GameEventFinish) {
      yield* _finishGame(event);
    } else if (event is GameEventSurrender) {
      await _surrender();
    } else if (event is _GameEventRunFailed) {
      if (state is GameState) {
        try {
          await (state as GameState).gameSessionRepository.finish();
        } catch (e, s) {
          // The game error explains the failure, so it is the one shown.
          debugPrint('Game cleanup after a failure failed: $e\n$s');
        }
      }
      // Shown as ErrorState by _mapEventToStateSafely.
      Error.throwWithStackTrace(event.error, event.stackTrace);
    } else if (event is GameEventShowHelp) {
      if (state is! GameState) return;
      final hintReadyAt =
          (state as GameState).gameSessionRepository.hintReadyAt;
      final readyAt = hintReadyAt.value;
      if (readyAt != null && clock.now().isBefore(readyAt)) return;

      final given = await _showHelp();
      if (given) {
        hintReadyAt.value = clock.now().add(hintCooldown);
        await _achievements.unlockAchievement(Achievement.use3Tips);
        await _achievements.unlockAchievement(Achievement.use30Tips);
      } else {
        final savedState = state;
        yield const GameNotificationState(GameNotification.hintUnavailable);
        yield savedState;
      }
    } else {
      throw ('Unexpected event: $event');
    }
  }

  /// Begins game loading sequence
  Stream<GameLifecycleState> _beginLoading() async* {
    if (_gameConfig.gameMode.isLocal) {
      // An update is optional: whatever goes wrong in it, the game starts
      // with the dictionary it has.
      try {
        // `await for`, not `yield*`, so that an error reaches the catch
        await for (final state in _checkForUpdates()) {
          yield state;
        }
      } catch (e, stackTrace) {
        addError(e, stackTrace);
      }
    }

    yield DataLoadingState();

    final scoreController = ScoreController.fromPrefs(
      _prefs,
      _gameConfig.gameMode,
    );
    final dictionary = await DictionaryFactory().createDictionary();
    final exclusions = await ExclusionsFactory(
      CountryListLoaderServiceFactory().createCountryList(),
      _exclusionMessages,
    ).createExclusions();

    yield GotDataState(
      DictionaryDecorator(dictionary, _prefs),
      exclusions,
      scoreController,
    );

    add(const GameEventGameStart());
  }

  Stream<GameLifecycleState> _runGame() async* {
    if (state is! GotDataState) throw ('Invalid state: $state!');
    final dataState = state as GotDataState;

    final session = GameSessionFactory.createForGameMode(
      config: _gameConfig,
      preferences: _prefs,
      codeOverrides: _codeOverrides,
      exclusions: dataState.exclusions,
      dictionary: dataState.dictionary,
      scoreController: dataState.scoreController,
      achievements: _achievements,
      playerNames: _playerNames,
      onUserInputAccepted: () => onUserInputAccepted?.call(),
      onUserMoveBegins: () => onUserMoveBegins?.call(),
    );
    final repository = GameSessionRepository(session);
    _turnGate = session.turnGate;

    yield GameState(
      repository,
      dataState.dictionary,
      dataState.scoreController,
    );

    // Send finish event when the game ends
    unawaited(
      repository
          .run()
          .then((GameResult result) => add(GameEventFinish(result)))
          .catchError((Object error, StackTrace stack) {
            if (!isClosed) add(_GameEventRunFailed(error, stack));
          }),
    );
  }

  /// Calls [DictionaryUpdater.checkForUpdates] to fetch updates from the server.
  /// Doesn't work in remote modes, just completes with an empty stream.
  Stream<CheckingForUpdatesState> _checkForUpdates() {
    return _dictionaryUpdater.checkForUpdates().map(
      (downloadPercent) => CheckingForUpdatesState(
        downloadPercent == -1
            ? CheckingForUpdatesStage.fetchingUpdate
            : CheckingForUpdatesStage.updating,
        downloadPercent,
      ),
    );
  }

  Stream<GameLifecycleState> _finishGame(GameEventFinish event) async* {
    if (state is! GameState) return;

    final gameState = state as GameState;
    await gameState.gameSessionRepository.finish();

    yield GameResultsState(event.gameResult, _gameConfig);
  }

  Future _surrender() async {
    if (state is GameState) {
      await (state as GameState).gameSessionRepository.surrender();
    }
  }

  /// Moves a random city on the letter of the move for the player. Returns
  /// `false` when the dictionary has none left.
  Future<bool> _showHelp() async {
    if (state is! GameState) return false;
    final gameState = state as GameState;

    final firstChar = findLastSuitableChar(
      gameState.gameSessionRepository.lastAcceptedWord,
    );
    final word = await (gameState.dictionary as DictionaryDecorator)
        .getRandomWord(firstChar.isEmpty ? 'а' : firstChar);
    if (word.isEmpty) return false;

    gameState.gameSessionRepository.sendInputWord(word);

    return true;
  }
}
