part of 'waiting_room_bloc.dart';

/// Base event for [WaitingRoomBloc]
abstract class WaitingRoomEvent extends Equatable {
  const WaitingRoomEvent();
}

/// Starts connection sequence
class ConnectEvent extends WaitingRoomEvent {
  const ConnectEvent();

  @override
  List<Object> get props => [];
}

/// Event that used to cancel connection
class CancelEvent extends WaitingRoomEvent {
  const CancelEvent();

  @override
  List<Object> get props => [];
}

/// Used when connection rejected (SocketException catched)
class OnConnectionFailedEvent extends WaitingRoomEvent {
  const OnConnectionFailedEvent();

  @override
  List<Object> get props => [];
}

/// Used internally to start awaiting for game request
class PlayEvent extends WaitingRoomEvent {
  final BaseProfileInfo opponent;

  const PlayEvent(this.opponent);

  @override
  List<Object> get props => [opponent];
}

/// Used internally to start the game
class StartGameEvent extends WaitingRoomEvent {
  final List<Player> players;

  const StartGameEvent(this.players) : assert(players != null);

  @override
  List<Object> get props => [players];
}
