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

/// Used to push waiting room screen with specified [host]
class LocalMultiplayerStartGame extends LocalMultiplayerState {
  /// Overrides of [AppConfig] for local game
  final AppConfig configOverrides;

  /// Overrides of [AccountManager] for local game
  final AccountManager accountManagerOverrides;

  LocalMultiplayerStartGame(this.configOverrides, this.accountManagerOverrides);

  @override
  List<Object> get props => [configOverrides, accountManagerOverrides];
}

/// Signals that user doesn't connected to the wi-fi network
class LocalMultiplayerNoWifiState extends LocalMultiplayerState {
  @override
  List<Object> get props => [];
}
