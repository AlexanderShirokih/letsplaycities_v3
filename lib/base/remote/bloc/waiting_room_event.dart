part of 'waiting_room_bloc.dart';

/// Base event for [WaitingRoomBloc]
abstract class WaitingRoomEvent extends Equatable {
  const WaitingRoomEvent();
}

/// Starts connection sequence
class NewGameRequestEvent extends WaitingRoomEvent {
  /// Optional friend-mode request
  final FriendGameRequest? request;

  const NewGameRequestEvent([this.request]);

  @override
  List<Object?> get props => [request];
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
class WaitForOpponentsEvent extends WaitingRoomEvent {
  final FriendGameRequest? request;

  const WaitForOpponentsEvent(this.request);

  @override
  List<Object?> get props => [request];
}

/// Used internally to signal negative invitation result
class InvitationNegativeResult extends WaitingRoomEvent {
  final InviteResultType result;
  final BaseProfileInfo target;

  const InvitationNegativeResult(this.result, this.target);

  @override
  List<Object> get props => [result, target];
}

/// Used internally to start the game
class StartGameEvent extends WaitingRoomEvent {
  final GameConfig config;

  const StartGameEvent(this.config);

  @override
  List<Object> get props => [config];
}
