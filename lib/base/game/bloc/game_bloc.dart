import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lets_play_cities/base/dictionary.dart';
import 'package:lets_play_cities/base/dictionary/dictionary_factory.dart';
import 'package:lets_play_cities/base/dictionary/dictionary_updater.dart';
import 'package:lets_play_cities/base/dictionary/dictionary_proxy.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:meta/meta.dart';

import '../game_mode.dart';

part 'game_events.dart';

part 'game_states.dart';

class GameBloc extends Bloc<GameStateEvent, GameLifecycleState> {
  final GamePreferences _prefs;
  final DictionaryUpdater _dictionaryUpdater;
  final GameMode _gameMode;

  GameBloc({
    GamePreferences prefs,
    DictionaryUpdater dictionaryUpdater,
    GameMode gameMode,
  })  : assert(prefs != null),
        assert(dictionaryUpdater != null),
        assert(gameMode != null),
        _prefs = prefs,
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
        break;
      default:
        // TODO: Handle this case.
        break;
    }
  }

  /// Begins game loading sequence
  Stream<GameLifecycleState> _beginLoading() async* {
    if (_gameMode.isLocal()) {
      yield* _checkForUpdates();
    }

    yield DataLoadingState();

    yield GameState(
      DictionaryProxy(
        await DictionaryFactory().loadDictionary(),
        _prefs,
      ),
    );

    add(GameStateEvent.GameStart);
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
}
