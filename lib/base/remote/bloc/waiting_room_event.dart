part of 'waiting_room_bloc.dart';

/// Base event for [WaitingRoomBloc]
abstract class WaitingRoomEvent extends Equatable {
  const WaitingRoomEvent();
}

/// Starts connection sequence
class ConnectEvent extends WaitingRoomEvent {
  /// Optional invitation target
  final BaseProfileInfo target;

  const ConnectEvent([this.target]);

  @override
  List<Object> get props => [target];
}

/// Event that used to cancel connection
class CancelEvent extends WaitingRoomEvent {
  const CancelEvent();

  @override
  List<Object> get props => [];
}

/// Used when connection rejected (SocketException catch)
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

/// Used internally to signal negative invitation result
class InvitationNegativeResult extends WaitingRoomEvent {
  final InviteResultType result;
  final BaseProfileInfo target;

  const InvitationNegativeResult(this.result, this.target)
      : assert(result != null),
        assert(target != null);

  @override
  List<Object> get props => [result, target];
}

/// Used internally to start the game
class StartGameEvent extends WaitingRoomEvent {
  final GameConfig config;

  const StartGameEvent(this.config) : assert(config != null);

  @override
  List<Object> get props => [config];
}
