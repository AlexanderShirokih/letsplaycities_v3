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

/// Signals that guest connections searching are running now
class LocalMultiplayerWaitingForConnections extends LocalMultiplayerState {
  @override
  List<Object> get props => [];
}

/// Starts connecting screen to connect to the local server.
class LocalMultiplayerJoiningState extends LocalMultiplayerState {
  @override
  List<Object> get props => [];
}

/// Signals that user doesn't connected to the wi-fi network
class LocalMultiplayerNoWifiState extends LocalMultiplayerState {
  @override
  List<Object> get props => [];
}
