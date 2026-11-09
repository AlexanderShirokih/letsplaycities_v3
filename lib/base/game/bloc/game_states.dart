part of 'game_bloc.dart';

/// Describes states of in the game lifecycle
@sealed
abstract class GameLifecycleState extends Equatable {
  const GameLifecycleState();
}

/// Default state used before game starts.
class InitialState extends GameLifecycleState {
  const InitialState();

  @override
  List<Object?> get props => [];
}

/// Stages for [CheckingForUpdatesState]
enum CheckingForUpdatesStage { fetchingUpdate, updating }

/// The state used when game doing checking for dictionary updates and downloading it
class CheckingForUpdatesState extends GameLifecycleState {
  final CheckingForUpdatesStage stage;
  final int stagePercent;

  const CheckingForUpdatesState(this.stage, this.stagePercent);

  @override
  List<Object?> get props => [stage, stagePercent];
}

/// The state used when tge game loads exclusions list and dictionary
/// to be able to start [GameState]
class DataLoadingState extends GameLifecycleState {
  const DataLoadingState();

  @override
  List<Object?> get props => [];
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
  const GotDataState(this.dictionary, this.exclusions, this.scoreController);

  @override
  List<Object?> get props => [dictionary, exclusions, scoreController];
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

  @override
  List<Object?> get props => [
    gameSessionRepository,
    dictionary,
    scoreController,
  ];
}

/// What [GameNotificationState] tells the player.
enum GameNotification {
  /// The player asked for a hint, but no rewarded ad is loaded yet.
  /// The dictionary has no city left on the letter of the move
  hintUnavailable,
}

/// Used to show notification snackbar
class GameNotificationState extends GameLifecycleState {
  final GameNotification notification;

  const GameNotificationState(this.notification);

  @override
  List<Object?> get props => [notification];
}

/// Used when the game ends
class GameResultsState extends GameLifecycleState {
  final GameResult gameResult;
  final GameConfig gameConfig;

  const GameResultsState(this.gameResult, this.gameConfig);

  @override
  List<Object?> get props => [gameResult, gameConfig];
}

/// Used when some fatal error happens
class ErrorState extends GameLifecycleState {
  final Object exception;
  final StackTrace stackTrace;

  const ErrorState(this.exception, this.stackTrace);

  @override
  List<Object?> get props => [exception, stackTrace];
}
