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

/// Triggers connection to running server
class LocalMultiplayerConnect extends LocalMultiplayerEvent {
  const LocalMultiplayerConnect();

  @override
  List<Object> get props => [];
}
