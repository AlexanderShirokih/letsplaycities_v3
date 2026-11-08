part of 'local_multiplayer_bloc.dart';

/// Events for [LocalMultiplayerBloc]
abstract class LocalMultiplayerEvent extends Equatable {
  const LocalMultiplayerEvent();
}

/// Triggers local server starting
class LocalMultiplayerCreate extends LocalMultiplayerEvent {
  const LocalMultiplayerCreate();

  @override
  List<Object> get props => [];
}

/// Tries to connect to chosen server address
class LocalMultiplayerConnect extends LocalMultiplayerEvent {
  final RemoteHost selectedHost;

  const LocalMultiplayerConnect(this.selectedHost);

  @override
  List<Object> get props => [selectedHost];
}

/// Stops the server that is starting and returns to the initial state
class LocalMultiplayerCancel extends LocalMultiplayerEvent {
  const LocalMultiplayerCancel();

  @override
  List<Object> get props => [];
}
