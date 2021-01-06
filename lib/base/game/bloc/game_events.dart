part of 'game_bloc.dart';

/// Events for managing [GameBloc]
@immutable
@sealed
class GameStateEvent {
  const GameStateEvent();
}

/// Used internally to begin data loading sequence
class GameEventBeginDataLoading extends GameStateEvent {
  const GameEventBeginDataLoading();
}

/// Used internally to run game loop
class GameEventGameStart extends GameStateEvent {
  const GameEventGameStart();
}

/// Used internally to normally finish the game and prepare to show game results
class GameEventFinish extends GameStateEvent with EquatableMixin {
  final GameResult gameResult;

  const GameEventFinish(this.gameResult);

  @override
  List<Object> get props => [gameResult];
}

/// Finishes the game and surrenders current player
class GameEventSurrender extends GameStateEvent {
  const GameEventSurrender();
}

/// Shows tip for player
class GameEventShowHelp extends GameStateEvent {
  const GameEventShowHelp();
}
