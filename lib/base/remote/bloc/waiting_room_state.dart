part of 'waiting_room_bloc.dart';

/// Base state class for [WaitingRoomBloc]
sealed class WaitingRoomState extends Equatable {
  const WaitingRoomState();

  @override
  List<Object?> get props => [];
}

/// Nothing is asked of the server
class Idle extends WaitingRoomState {
  const Idle();
}

/// The connection opens, or the request waits for its first answer
class Connecting extends WaitingRoomState {
  const Connecting();
}

/// In the queue of random matching since [since]
class Queued extends WaitingRoomState {
  final DateTime since;

  const Queued(this.since);

  @override
  List<Object?> get props => [since];
}

/// Waits for [target] to answer the invitation
class Inviting extends WaitingRoomState {
  final LpsUser target;

  const Inviting(this.target);

  @override
  List<Object?> get props => [target];
}

/// The invitation ended with [status] without a game. [target] is the
/// invited friend, `null` when the user answered an invitation.
class InviteFinished extends WaitingRoomState {
  final LpsUser? target;
  final protocol.InviteStatusKind status;

  const InviteFinished(this.target, this.status);

  @override
  List<Object?> get props => [target, status];
}

/// The server refused to invite [target] so soon after the previous
/// invitation
class RateLimited extends WaitingRoomState {
  final LpsUser target;

  const RateLimited(this.target);

  @override
  List<Object?> get props => [target];
}

/// The server refused the accepted invitation (`invalid_state`): it does
/// not see the user free to play it
class InviteReplyRejected extends WaitingRoomState {
  const InviteReplyRejected();
}

/// The opponent is found: the screen starts the game of [config]
class Starting extends WaitingRoomState {
  final GameConfig config;

  const Starting(this.config);

  @override
  List<Object?> get props => [config];
}

/// The request failed. [error] is an `ApiException` of a refused upgrade, a
/// [ConnectionException] or [RemoteIOException] of a lost connection, or a
/// [ProtocolErrorException] (`replaced`, `unsupported_protocol`). [retry]
/// sends the request again.
class Failed extends WaitingRoomState {
  final Exception error;
  final WaitingRoomEvent? retry;

  const Failed(this.error, {this.retry});

  @override
  List<Object?> get props => [error, retry];
}
