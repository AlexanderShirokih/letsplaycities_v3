import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Base class for all outgoing socket messages
abstract class OutgoingMessage extends Equatable {
  const OutgoingMessage();

  @override
  List<Object> get props => [];
}

/// Startup message used to authorize user on WS server.
class LogInMessage extends OutgoingMessage {
  /// Actual protocol version
  final int version = 5;

  /// Client build code
  final int clientBuild;

  /// Client build string representation
  final String clientVersion;

  /// `true` if user wants to receive messages from another users
  final bool canReceiveMessages;

  /// Firebase token
  final String firebaseToken;

  /// Credentials: User ID
  final int uid;

  /// Credentials: Access hash
  final String hash;

  const LogInMessage({
    @required this.clientBuild,
    @required this.clientVersion,
    @required this.canReceiveMessages,
    @required this.firebaseToken,
    @required this.uid,
    @required this.hash,
  });

  @override
  List<Object> get props => [
        clientBuild,
        clientVersion,
        canReceiveMessages,
        firebaseToken,
        uid,
        hash,
      ];
}

/// Game modes. Random pair game or playing with friend
enum PlayMode { RANDOM_PAIR, FRIEND }

/// Indicates request for beginning a new game.
class PlayMessage extends OutgoingMessage {
  /// Requesting game mode
  final PlayMode mode;

  /// Opponent ID. used in [PlayMode.FRIEND] mode
  final int oppUid;

  const PlayMessage({
    @required this.mode,
    @required this.oppUid,
  }) : assert(mode != null);

  @override
  List<Object> get props => [mode, oppUid];
}

/// Used to send users word to server
class OutgoingWordMessage extends OutgoingMessage {
  /// Word to be checked
  final String word;

  const OutgoingWordMessage({@required this.word});
}

/// Used to send users message to server
class OutgoingChatMessage extends OutgoingMessage {
  /// Message to be sent
  final String msg;

  const OutgoingChatMessage({@required this.msg});
}

enum InvitationResult { accept, decline }

/// Result decision on input request
class InvitationResultMessage extends OutgoingMessage {
  /// Users decision
  final InvitationResult result;

  /// Inviter ID
  final int oppId;

  const InvitationResultMessage({
    @required this.result,
    @required this.oppId,
  });

  @override
  List<Object> get props => [result, oppId];
}
