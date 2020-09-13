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
import 'package:lets_play_cities/utils/string_utils.dart';
import 'package:meta/meta.dart';

import '../game_mode.dart';
import '../game_session_factory.dart';
import 'package:http/http.dart' as http;

part 'game_events.dart';

part 'game_states.dart';

class GameBloc extends Bloc<GameStateEvent, GameLifecycleState> {
  final http.Client _http = http.Client();
  final GamePreferences _prefs;
  final LocalizationService _localizations;
  final GameMode _gameMode;

  OnUserInputAccepted onUserInputAccepted;
  DictionaryUpdater _dictionaryUpdater;

  @override
  Future<void> close() async {
    if (state is GameState) {
      final gameState = state as GameState;
      await gameState.gameSessionRepository.finish();
    }
    _http.close();
    return super.close();
  }

  GameBloc({
    LocalizationService localizations,
    GamePreferences prefs,
    GameMode gameMode,
  })  : assert(prefs != null),
        assert(gameMode != null),
        assert(localizations != null),
        _prefs = prefs,
        _localizations = localizations,
        _gameMode = gameMode,
        super(InitialState()) {
    add(GameStateEvent.BeginDataLoading);
    _dictionaryUpdater = DictionaryUpdater(_prefs, _http);
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
      case GameStateEvent.ShowHelp:
        await _showHelp();
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

    yield GameState(repository, dataState.dictionary);

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

  Future<void> _showHelp() async {
    if (state is GameState) {
      final gameState = state as GameState;
      final firstChar = findLastSuitableChar(
          gameState.gameSessionRepository.lastAcceptedWord);
      final word = await gameState.dictionary
          .getRandomWord(firstChar.isEmpty ? "а" : firstChar);
      if (word.isNotEmpty) gameState.gameSessionRepository.sendInputWord(word);
    }
  }
}
