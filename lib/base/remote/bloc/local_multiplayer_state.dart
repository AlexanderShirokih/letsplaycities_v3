part of 'local_multiplayer_bloc.dart';

/// States for [LocalMultiplayerBloc]
abstract class LocalMultiplayerState extends Equatable {
  const LocalMultiplayerState();
}

/// Default multiplayer state used to show screen with create connection and join buttons
class LocalMultiplayerInitial extends LocalMultiplayerState {
  @override
  List<Object> get props => [];
}

/// Signals that game server currently starting
class LocalMultiplayerStartingServer extends LocalMultiplayerState {
  @override
  List<Object> get props => [];
}

/// Used on error while server initialization
class LocalMultiplayerErrorState extends LocalMultiplayerState {
  @override
  List<Object> get props => [];
}

/// Used to push the waiting room of the game on the LAN host of [config]
class LocalMultiplayerStartGame extends LocalMultiplayerState {
  /// The LAN host of the game
  final AppConfig config;

  const LocalMultiplayerStartGame(this.config);

  @override
  List<Object> get props => [config];
}

/// Signals that user doesn't connected to the wi-fi network
class LocalMultiplayerNoWifiState extends LocalMultiplayerState {
  @override
  List<Object> get props => [];
}
