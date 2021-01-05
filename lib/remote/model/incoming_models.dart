import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';
import 'package:lets_play_cities/base/data/word_result.dart';
import 'package:lets_play_cities/remote/models.dart';

/// Base class for all messages received from server
abstract class IncomingMessage extends Equatable {
  const IncomingMessage();

  @override
  List<Object> get props => [];
}

/// Indicates that client was connected to server
class ConnectedMessage extends IncomingMessage {}

/// Indicates that connection between client and server has stopped.
class DisconnectedMessage extends IncomingMessage {}

/// First message after successful connection.
class LoggedInMessage extends IncomingMessage {
  /// Contains latest actual version of client application
  final int newerBuild;

  const LoggedInMessage({@required this.newerBuild});

  @override
  List<Object> get props => [newerBuild];
}

/// First message if user was forbidden.
class BannedMessage extends IncomingMessage {
  /// Ban reason
  final String banReason;

  const BannedMessage({@required this.banReason});

  @override
  List<Object> get props => [banReason];
}

/// Indicates that the battle has started
class JoinMessage extends IncomingMessage {
  /// `true` if opponent wants to receive messages from user.
  final bool canReceiveMessages;

  /// `true` if you should make first move in the game.
  final bool youStarter;

  /// Opponent account info
  final ProfileInfo opponent;

  const JoinMessage({
    @required this.canReceiveMessages,
    @required this.youStarter,
    @required this.opponent,
  });

  @override
  List<Object> get props => [canReceiveMessages, youStarter, opponent];
}

/// Indicates an word validation result or input work from another opponents
class WordMessage extends IncomingMessage {
  /// Word type (validation result or incoming word)
  final WordResult result;

  /// The word
  final String word;

  /// Owner ID
  final int ownerId;

  const WordMessage({
    @required this.result,
    @required this.word,
    @required this.ownerId,
  });

  @override
  List<Object> get props => [result, word, ownerId];
}

/// Describes message received from another user
class ChatMessage extends IncomingMessage {
  final String message;
  final int ownerId;

  const ChatMessage({
    @required this.message,
    @required this.ownerId,
  });

  @override
  List<Object> get props => [message, ownerId];
}

/// Indicates that move time has gone
class TimeoutMessage extends IncomingMessage {}
