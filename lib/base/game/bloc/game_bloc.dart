import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lets_play_cities/base/dictionary.dart';
import 'package:lets_play_cities/base/dictionary/impl/country_list_loader_factory.dart';
import 'package:lets_play_cities/base/dictionary/impl/dictionary_factory.dart';
import 'package:lets_play_cities/base/dictionary/impl/exclusions_factory.dart';
import 'package:lets_play_cities/base/game/game_result.dart';
import 'package:lets_play_cities/base/game/handlers.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/base/repositories/game_session_repo.dart';
import 'package:lets_play_cities/base/scoring.dart';
import 'package:lets_play_cities/l18n/localization_service.dart';
import 'package:lets_play_cities/remote/remote_module.dart';
import 'package:lets_play_cities/utils/string_utils.dart';
import 'package:meta/meta.dart';
import 'package:pedantic/pedantic.dart';

import '../game_config.dart';
import '../game_mode.dart';
import '../game_session_factory.dart';

part 'game_events.dart';

part 'game_states.dart';

class GameBloc extends Bloc<GameStateEvent, GameLifecycleState> {
  final GamePreferences _prefs;
  final LocalizationService _localizations;
  final GameConfig _gameConfig;

  OnUserInputAccepted onUserInputAccepted;
  DictionaryUpdater _dictionaryUpdater;

  @override
  Future<void> close() async {
    if (state is GameState) {
      await (state as GameState).gameSessionRepository.finish();
    }
    return super.close();
  }

  GameBloc({
    @required LocalizationService localizations,
    @required GamePreferences prefs,
    @required GameConfig gameConfig,
  })  : assert(prefs != null),
        assert(gameConfig != null),
        assert(localizations != null),
        _prefs = prefs,
        _localizations = localizations,
        _gameConfig = gameConfig,
        super(InitialState()) {
    add(const GameEventBeginDataLoading());
    _dictionaryUpdater = DictionaryUpdater(_prefs, getDio());
  }

  @override
  Stream<GameLifecycleState> mapEventToState(GameStateEvent event) =>
      _mapEventToState(event).transform(StreamTransformer.fromHandlers(
          handleError: (Object e, StackTrace stackTrace,
                  EventSink<GameLifecycleState> sink) =>
              sink.add(ErrorState(e, stackTrace))));

  Stream<GameLifecycleState> _mapEventToState(GameStateEvent event) async* {
    if (event is GameEventBeginDataLoading) {
      yield* _beginLoading();
    } else if (event is GameEventGameStart) {
      yield* _runGame();
    } else if (event is GameEventFinish) {
      yield* _finishGame(event);
    } else if (event is GameEventSurrender) {
      await _surrender();
    } else if (event is GameEventShowHelp) {
      await _showHelp();
    } else {
      throw ('Unexpected event: $event');
    }
  }

  /// Begins game loading sequence
  Stream<GameLifecycleState> _beginLoading() async* {
    if (_gameConfig.gameMode.isLocal()) {
      yield* _checkForUpdates();
    }

    yield DataLoadingState.empty();

    final scoreController = ScoreController.fromPrefs(_prefs);
    final dictionary = await DictionaryFactory().createDictionary();
    final exclusions = await ExclusionsFactory(
            CountryListLoaderServiceFactory().createCountryList(),
            _localizations.exclusionDescriptions)
        .createExclusions();

    yield DataLoadingState.forData(
      DictionaryDecorator(
        dictionary,
        _prefs,
      ),
      exclusions,
      scoreController,
    );

    add(const GameEventGameStart());
  }

  Stream<GameLifecycleState> _runGame() async* {
    if (!(state is DataLoadingState)) throw ('Invalid state: $state!');
    final dataState = state as DataLoadingState;

    final repository = GameSessionRepository(
      GameSessionFactory.createForGameMode(
        config: _gameConfig,
        preferences: _prefs,
        exclusions: dataState.exclusions,
        dictionary: dataState.dictionary,
        scoreController: dataState.scoreController,
        onUserInputAccepted: () => onUserInputAccepted(),
      ),
    );

    yield GameState(
        repository, dataState.dictionary, dataState.scoreController);

    // Send finish event when the game ends
    unawaited(repository
        .run()
        .then((GameResult result) => add(GameEventFinish(result)))
        .catchError((error, stack) {
      print('Error: $error,\nStack: $stack');
    }));
  }

  /// Calls [DictionaryUpdater.checkForUpdates] to fetch updates from the server.
  /// Doesn't work in remote modes, just completes with an empty stream.
  Stream<CheckingForUpdatesState> _checkForUpdates() {
    return _dictionaryUpdater.checkForUpdates().map((downloadPercent) =>
        CheckingForUpdatesState(
            downloadPercent == -1
                ? CheckingForUpdatesStage.FetchingUpdate
                : CheckingForUpdatesStage.Updating,
            downloadPercent));
  }

  Stream<GameLifecycleState> _finishGame(GameEventFinish event) async* {
    if (!(state is GameState)) return;

    final gameState = state as GameState;
    await gameState.gameSessionRepository.finish();

    yield GameResultsState(event.gameResult, _gameConfig);
  }

  Future _surrender() async {
    if (state is GameState) {
      await (state as GameState).gameSessionRepository.surrender();
    }
  }

  Future<void> _showHelp() async {
    if (state is GameState) {
      final gameState = state as GameState;
      final firstChar = findLastSuitableChar(
          gameState.gameSessionRepository.lastAcceptedWord);
      final word = await gameState.dictionary
          .getRandomWord(firstChar.isEmpty ? 'а' : firstChar);
      if (word.isNotEmpty) gameState.gameSessionRepository.sendInputWord(word);
    }
  }
}
