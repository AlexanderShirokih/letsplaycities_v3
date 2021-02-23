import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:lets_play_cities/base/ads/advertising_helper.dart';
import 'package:lets_play_cities/base/dictionary.dart';
import 'package:lets_play_cities/base/dictionary/countrycode_overrides.dart';
import 'package:lets_play_cities/base/dictionary/impl/country_list_loader_factory.dart';
import 'package:lets_play_cities/base/dictionary/impl/dictionary_factory.dart';
import 'package:lets_play_cities/base/dictionary/impl/exclusions_factory.dart';
import 'package:lets_play_cities/base/game/game_result.dart';
import 'package:lets_play_cities/base/game/handlers.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/base/repositories/game_session_repo.dart';
import 'package:lets_play_cities/base/scoring.dart';
import 'package:lets_play_cities/l18n/localization_service.dart';
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
  final DictionaryUpdater _dictionaryUpdater;
  final CountryCodeOverrides _codeOverrides;
  final GameConfig _gameConfig;
  final AdManager _adManager;

  OnUserInputAccepted? onUserInputAccepted;
  OnUserMoveBegins? onUserMoveBegins;

  @override
  Future<void> close() async {
    if (state is GameState) {
      await (state as GameState).gameSessionRepository.finish();
    }
    return super.close();
  }

  GameBloc({
    required GameConfig gameConfig,
  })   : _prefs = GetIt.instance.get<GamePreferences>(),
        _localizations = GetIt.instance.get<LocalizationService>(),
        _codeOverrides = GetIt.instance.get<CountryCodeOverrides>(),
        _gameConfig = gameConfig,
        _dictionaryUpdater = DictionaryUpdater(),
        _adManager = GetIt.instance.get<AdManager>(),
        super(InitialState()) {
    _adManager.setUpAds(() {
      if (state is GameState) {
        final gameState = state as GameState;

        final firstChar = findLastSuitableChar(
            gameState.gameSessionRepository.lastAcceptedWord);

        (gameState.dictionary as DictionaryDecorator)
            .getRandomWord(firstChar.isEmpty ? 'а' : firstChar)
            .then((word) {
          if (word.isNotEmpty) {
            gameState.gameSessionRepository.sendInputWord(word);
          }
        });
      }
    });

    add(const GameEventBeginDataLoading());
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
    if (_gameConfig.gameMode.isLocal) {
      yield* _checkForUpdates();
    }

    yield DataLoadingState();

    final scoreController =
        ScoreController.fromPrefs(_prefs, _gameConfig.gameMode);
    final dictionary = await DictionaryFactory().createDictionary();
    final exclusions = await ExclusionsFactory(
            CountryListLoaderServiceFactory().createCountryList(),
            _localizations.exclusionDescriptions)
        .createExclusions();

    yield GotDataState(
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
    if (!(state is GotDataState)) throw ('Invalid state: $state!');
    final dataState = state as GotDataState;

    final repository = GameSessionRepository(
      GameSessionFactory.createForGameMode(
          config: _gameConfig,
          preferences: _prefs,
          codeOverrides: _codeOverrides,
          exclusions: dataState.exclusions,
          dictionary: dataState.dictionary,
          scoreController: dataState.scoreController,
          onUserInputAccepted: () => onUserInputAccepted?.call(),
          onUserMoveBegins: () => onUserMoveBegins?.call()),
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
    await _adManager.showRewarded();
  }
}
