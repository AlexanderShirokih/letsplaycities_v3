part of 'game_bloc.dart';

/// Events for managing [GameBloc]
enum GameStateEvent {
  /// Used internally to begin data loading sequence
  BeginDataLoading,

  /// Used internally to run game loop
  GameStart,

  /// Used internally to normally finish the game and prepare to show game results
  Finish,

  /// Finishes the game and surrenders current player
  Surrender
}
