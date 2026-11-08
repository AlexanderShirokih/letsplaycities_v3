part of 'waiting_room_bloc.dart';

/// Base event for [WaitingRoomBloc]
sealed class WaitingRoomEvent extends Equatable {
  const WaitingRoomEvent();

  @override
  List<Object?> get props => [];
}

/// Looks for a random opponent
class FindPressed extends WaitingRoomEvent {
  const FindPressed();
}

/// Invites [friend] to a game
class InvitePressed extends WaitingRoomEvent {
  final LpsUser friend;

  const InvitePressed(this.friend);

  @override
  List<Object?> get props => [friend];
}

/// Leaves the queue or withdraws the invitation
class CancelPressed extends WaitingRoomEvent {
  const CancelPressed();
}

/// Answers the invitation of user [fromId]; an accepted one waits for the
/// match
class ReplyToInvite extends WaitingRoomEvent {
  final int fromId;
  final bool accept;

  const ReplyToInvite(this.fromId, this.accept);

  @override
  List<Object?> get props => [fromId, accept];
}

/// The connection of request [request] is open: the request is sent
class _Connected extends WaitingRoomEvent {
  final int request;
  final WaitingRoomEvent source;

  const _Connected(this.request, this.source);

  @override
  List<Object?> get props => [request, source];
}

/// The request [request] failed with [error]
class _RequestFailed extends WaitingRoomEvent {
  final int request;
  final WaitingRoomEvent source;
  final Exception error;

  const _RequestFailed(this.request, this.source, this.error);

  @override
  List<Object?> get props => [request, source, error];
}

/// The server answered request [request]
class _ServerSaid extends WaitingRoomEvent {
  final int request;
  final protocol.WaitingEvent message;

  const _ServerSaid(this.request, this.message);

  @override
  List<Object?> get props => [request, message];
}

/// The match of request [request] built the game of [config]
class _Matched extends WaitingRoomEvent {
  final int request;
  final GameConfig config;

  const _Matched(this.request, this.config);

  @override
  List<Object?> get props => [request, config];
}

/// The connection ended while request [request] waited
class _Closed extends WaitingRoomEvent {
  final int request;
  final GameConnectionClose close;

  const _Closed(this.request, this.close);

  @override
  List<Object?> get props => [request, close];
}
