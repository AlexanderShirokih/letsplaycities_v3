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
  const DataLoadingState();
}

/// The state used when data is ready
class GotDataState extends GameLifecycleState {
  /// Instance of loaded dictionary
  final DictionaryDecorator dictionary;

  /// Instance of loaded exclusions
  final ExclusionsService exclusions;

  /// Instance of class that handles scores and defines winner
  final ScoreController scoreController;

  /// Creates [DataLoadingState] containing loaded data
  const GotDataState(
    this.dictionary,
    this.exclusions,
    this.scoreController,
  );
}

/// The state used during the game.
/// Starts after [DataLoadingState]
class GameState extends GameLifecycleState {
  final DictionaryService dictionary;
  final ScoreController scoreController;
  final GameSessionRepository gameSessionRepository;

  const GameState(
    this.gameSessionRepository,
    this.dictionary,
    this.scoreController,
  );
}

/// Used when the game ends
class GameResultsState extends GameLifecycleState {
  final GameResult gameResult;
  final GameConfig gameConfig;

  const GameResultsState(this.gameResult, this.gameConfig);
}

/// Used when some fatal error happens
class ErrorState extends GameLifecycleState {
  final Object exception;
  final StackTrace stackTrace;

  const ErrorState(this.exception, this.stackTrace);
}
