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

/// The state used when game loads exclusions list and dictionary
class DataLoadingState extends GameLifecycleState {
  const DataLoadingState();
}

/// The state used during the game.
class GameState extends GameLifecycleState {
  final GameFacade gameFacade;

  const GameState(this.gameFacade);
}

/// Used when the game ends
class GameResultsState extends GameLifecycleState {}
