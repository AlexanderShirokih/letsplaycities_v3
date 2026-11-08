import 'package:equatable/equatable.dart';
import 'package:lets_play_cities/remote/model/lps_user.dart';
import 'package:lets_play_cities/remote/model/social.dart';

/// Message that the client sends over `WS /v1/game`
sealed class ClientGameMessage extends Equatable {
  const ClientGameMessage();

  @override
  List<Object?> get props => [];
}

/// First message of a connection
class Hello extends ClientGameMessage {
  final int protocol;
  final String client;
  final String name;

  const Hello({required this.protocol, required this.client, this.name = ''});

  @override
  List<Object?> get props => [protocol, client, name];
}

/// Enters the queue of random matching
class Find extends ClientGameMessage {
  const Find();
}

/// Invites a friend
class Invite extends ClientGameMessage {
  final int userId;

  const Invite(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Answers the invitation of [userId]
class InviteReply extends ClientGameMessage {
  final int userId;
  final bool accept;

  const InviteReply(this.userId, {required this.accept});

  @override
  List<Object?> get props => [userId, accept];
}

/// Leaves the queue or withdraws the invitation
class Cancel extends ClientGameMessage {
  const Cancel();
}

/// A move
class WordMsg extends ClientGameMessage {
  final String text;

  const WordMsg(this.text);

  @override
  List<Object?> get props => [text];
}

/// A chat message to the opponent
class ChatMsg extends ClientGameMessage {
  final String text;

  const ChatMsg(this.text);

  @override
  List<Object?> get props => [text];
}

/// Surrenders
class Leave extends ClientGameMessage {
  const Leave();
}

/// Message that the server sends over `WS /v1/game`
sealed class ServerGameMessage extends Equatable {
  const ServerGameMessage();

  @override
  List<Object?> get props => [];
}

/// What the server says while the client waits for a game: [Queued],
/// [InviteStatus], [Match] or [ProtocolError]
sealed class WaitingEvent {}

/// Answer to [Hello]
class Welcome extends ServerGameMessage {
  final LpsUser user;

  const Welcome(this.user);

  @override
  List<Object?> get props => [user];
}

/// The client waits in the queue
class Queued extends ServerGameMessage implements WaitingEvent {
  const Queued();
}

/// What happened to an invitation
enum InviteStatusKind {
  sent,
  declined,
  busy,
  offline,
  notFriends,
  blocked,
  expired;

  /// Returns the status the protocol names [wire]. Throws [FormatException]
  /// for an unknown name.
  static InviteStatusKind fromWire(String wire) => values.firstWhere(
    (value) => value.name == wire,
    orElse: () => throw FormatException('Unknown invite status "$wire"'),
  );
}

class InviteStatus extends ServerGameMessage implements WaitingEvent {
  final int userId;
  final InviteStatusKind status;

  const InviteStatus(this.userId, this.status);

  @override
  List<Object?> get props => [userId, status];
}

/// The opponent of a game
class MatchOpponent extends Equatable {
  final int id;
  final String name;
  final String? avatarHash;
  final Friendship friendship;

  const MatchOpponent({
    required this.id,
    required this.name,
    this.avatarHash,
    required this.friendship,
  });

  @override
  List<Object?> get props => [id, name, avatarHash, friendship];
}

/// A game has started
class Match extends ServerGameMessage implements WaitingEvent {
  final int gameId;
  final MatchOpponent opponent;
  final bool youStart;
  final int moveTimeSec;

  const Match({
    required this.gameId,
    required this.opponent,
    required this.youStart,
    required this.moveTimeSec,
  });

  @override
  List<Object?> get props => [gameId, opponent, youStart, moveTimeSec];
}

/// Verdict of the server on a move
enum WordStatus {
  accepted,
  alreadyUsed,
  unknown,
  wrongLetter,
  notYourTurn;

  /// Returns the status the protocol names [wire]. Throws [FormatException]
  /// for an unknown name.
  static WordStatus fromWire(String wire) => values.firstWhere(
    (value) => value.name == wire,
    orElse: () => throw FormatException('Unknown word status "$wire"'),
  );
}

/// A move of user [by] and its verdict
class WordResultMsg extends ServerGameMessage {
  final int by;
  final String text;
  final WordStatus status;

  const WordResultMsg(this.by, this.text, this.status);

  @override
  List<Object?> get props => [by, text, status];
}

/// A chat message from user [by]
class ChatIn extends ServerGameMessage {
  final int by;
  final String text;

  const ChatIn(this.by, this.text);

  @override
  List<Object?> get props => [by, text];
}

/// Why a game ended
enum GameOverReason {
  timeout,
  opponentLeft,
  surrender;

  /// Returns the reason the protocol names [wire]. Throws [FormatException]
  /// for an unknown name.
  static GameOverReason fromWire(String wire) => values.firstWhere(
    (value) => value.name == wire,
    orElse: () => throw FormatException('Unknown game over reason "$wire"'),
  );
}

/// The game has ended; [loser] is the id of the user that lost
class GameOver extends ServerGameMessage {
  final GameOverReason reason;
  final int loser;
  final int words;
  final int durationSec;

  const GameOver({
    required this.reason,
    required this.loser,
    required this.words,
    required this.durationSec,
  });

  @override
  List<Object?> get props => [reason, loser, words, durationSec];
}

/// The server rejected a message: `bad_message`, `hello_required`,
/// `invalid_state`, `unsupported_protocol`, `replaced`, `rate_limited`
class ProtocolError extends ServerGameMessage implements WaitingEvent {
  /// Another connection of the same user ousted this one
  static const replaced = 'replaced';

  /// An invitation came sooner than 2 s after the previous one
  static const rateLimited = 'rate_limited';

  /// The message does not fit the state of the user on the server
  static const invalidState = 'invalid_state';

  /// The server does not speak the protocol of `hello`
  static const unsupportedProtocol = 'unsupported_protocol';

  final String code;

  const ProtocolError(this.code);

  @override
  List<Object?> get props => [code];
}
