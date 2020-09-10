part of 'game_bloc.dart';

/// Describes states of in the game lifecycle
@sealed
abstract class GameLifecycleState {
  const GameLifecycleState();
}

/// Default state used before game starts.
class InitialState extends GameLifecycleState {
  const InitialState();
}

/// Stages for [CheckingForUpdatesState]
enum CheckingForUpdatesStage { FetchingUpdate, Updating }

/// The state used when game doing checking for dictionary updates and downloading it
class CheckingForUpdatesState extends GameLifecycleState {
  final CheckingForUpdatesStage stage;
  final int stagePercent;

  const CheckingForUpdatesState(this.stage, this.stagePercent);
}

/// The state used when tge game loads exclusions list and dictionary
/// to be able to start [GameState]
class DataLoadingState extends GameLifecycleState {
  /// Instance of loaded dictionary
  final DictionaryService dictionary;

  /// Instance of loaded exclusions
  final ExclusionsService exclusions;

  /// Instance to class that handles scores and defines winner
  final ScoreController scoreController;

  /// Creates [DataLoadingState] without any loaded data
  const DataLoadingState.empty()
      : dictionary = null,
        exclusions = null,
        scoreController = null;

  /// Creates [DataLoadingState] containing loaded data
  const DataLoadingState.forData(
    this.dictionary,
    this.exclusions,
    this.scoreController,
  )   : assert(dictionary != null),
        assert(exclusions != null),
        assert(scoreController != null);

  /// `true` when the state contains loaded data
  bool get isLoaded => dictionary != null && exclusions != null;
}

/// The state used during the game.
/// Starts after [DataLoadingState]
class GameState extends GameLifecycleState {
  final GameSessionRepository gameSessionRepository;

  const GameState(this.gameSessionRepository);
}

/// Used when the game ends
class GameResultsState extends GameLifecycleState {}
