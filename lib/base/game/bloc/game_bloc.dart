import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lets_play_cities/base/dictionary.dart';
import 'package:lets_play_cities/base/dictionary/impl/country_list_loader_factory.dart';
import 'package:lets_play_cities/base/dictionary/impl/dictionary_factory.dart';
import 'package:lets_play_cities/base/dictionary/impl/exclusions_factory.dart';
import 'package:lets_play_cities/base/game/scoring/score_controller.dart';
import 'package:lets_play_cities/base/repositories/game_session_repo.dart';
import 'package:lets_play_cities/base/game/handlers/local_endpoint.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/l18n/localization_service.dart';
import 'package:meta/meta.dart';

import '../game_mode.dart';
import '../game_session_factory.dart';

part 'game_events.dart';

part 'game_states.dart';

class GameBloc extends Bloc<GameStateEvent, GameLifecycleState> {
  final GamePreferences _prefs;
  final LocalizationService _localizations;
  final DictionaryUpdater _dictionaryUpdater;
  final GameMode _gameMode;

  OnUserInputAccepted onUserInputAccepted;

  GameBloc({
    LocalizationService localizations,
    GamePreferences prefs,
    DictionaryUpdater dictionaryUpdater,
    GameMode gameMode,
  })  : assert(prefs != null),
        assert(dictionaryUpdater != null),
        assert(gameMode != null),
        assert(localizations != null),
        _prefs = prefs,
        _localizations = localizations,
        _dictionaryUpdater = dictionaryUpdater,
        _gameMode = gameMode,
        super(InitialState()) {
    add(GameStateEvent.BeginDataLoading);
  }

  @override
  Stream<GameLifecycleState> mapEventToState(GameStateEvent event) async* {
    switch (event) {
      case GameStateEvent.BeginDataLoading:
        yield* _beginLoading();
        break;
      case GameStateEvent.GameStart:
        yield* _runGame();
        break;
      case GameStateEvent.Finish:
        yield* _finishGame();
        break;
      case GameStateEvent.Surrender:
        _surrender();
        break;
      default:
        throw ("Unexpected event: $event");
    }
  }

  /// Begins game loading sequence
  Stream<GameLifecycleState> _beginLoading() async* {
    if (_gameMode.isLocal()) {
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

    add(GameStateEvent.GameStart);
  }

  Stream<GameLifecycleState> _runGame() async* {
    if (!(state is DataLoadingState)) throw ("Invalid state: $state!");
    final DataLoadingState dataState = state as DataLoadingState;

    final repository = GameSessionRepository(
      GameSessionFactory.createForGameMode(
        mode: _gameMode,
        exclusions: dataState.exclusions,
        dictionary: dataState.dictionary,
        onUserInputAccepted: () => onUserInputAccepted(),
        timeLimit: _prefs.timeLimit,
        scoreController: dataState.scoreController,
      ),
    );

    yield GameState(repository);

    // await for game ends
    repository.run().then((_) {
      add(GameStateEvent.Finish);
    });
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

  Stream<GameLifecycleState> _finishGame() async* {
    if (!(state is GameState)) return;
    final gameState = state as GameState;

    await gameState.gameSessionRepository.finish();

    yield GameResultsState();
  }

  void _surrender() {
    if (state is GameState) {
      (state as GameState).gameSessionRepository.surrender();
    }
  }
}
