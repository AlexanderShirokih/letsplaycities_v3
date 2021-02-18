import 'dart:convert';

import 'package:lets_play_cities/base/data/word_result.dart';
import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:lets_play_cities/remote/model/auth_type.dart';
import 'package:lets_play_cities/remote/model/client_messages.dart';
import 'package:lets_play_cities/remote/model/profile_info.dart';
import 'package:lets_play_cities/remote/model/server_messages.dart';

import 'connection_transformer.dart';

class BackJsonMessageConverter
    extends MessageConverter<ClientMessage, ServerMessage> {
  @override
  ClientMessage decode(String data) {
    Map<String, dynamic> message = jsonDecode(data);
    final action = message['action'];
    if (action == null) {
      throw UnknownMessageException('No action provided!');
    }
    switch (action) {
      case 'login':
        final version = message['version'] ?? 0;
        if (version < 5) {
          throw RemoteException(
              'Unsupported protocol version! version: $version');
        }

        return LogInMessage(
          uid: message['uid'],
          hash: 'remote_hash',
          firebaseToken: '',
          canReceiveMessages: message['canReceiveMessages'],
          clientVersion: message['clientVersion'],
          clientBuild: message['clientBuild'],
        );
      case 'play':
        return PlayMessage(
          mode: PlayModeExtensions.fromString(message['mode']),
          oppUid: message['oppUid'],
        );
      case 'word':
        return OutgoingWordMessage(
          word: message['word'],
        );
      case 'msg':
        return OutgoingChatMessage(
          msg: message['msg'],
        );
    }
    throw UnknownMessageException('Unexpected kind of message: $action');
  }

  @override
  String encode(ServerMessage message) => jsonEncode(_encodeMessage(message));

  Map<String, dynamic> _encodeMessage(ServerMessage message) {
    if (message is LoggedInMessage) {
      return {
        'action': 'logged_in',
        'newerBuild': message.newerBuild,
      };
    } else if (message is BannedMessage) {
      return {
        'action': 'login_error',
        'banReason': message.banReason,
      };
    } else if (message is JoinMessage) {
      return {
        'action': 'join',
        'canReceiveMessages': message.canReceiveMessages,
        'youStarter': message.youStarter,
        'oppUid': message.opponent.userId,
        'login': message.opponent.login,
        'friendshipStatus': message.opponent.friendshipStatus.asString(),
        'authType': message.opponent.authType.fullName,
      };
    } else if (message is WordMessage) {
      return {
        'action': 'word',
        'ownerId': message.ownerId,
        'word': message.word,
        'result': message.result.asString()
      };
    } else if (message is ChatMessage) {
      return {
        'action': 'msg',
        'msg': message.message,
        'ownerId': message.ownerId,
      };
    } else if (message is TimeoutMessage) {
      return {
        'action': 'timeout',
      };
    } else if (message is DisconnectedMessage) {
      return {
        'action': 'leave',
      };
    }
    throw UnknownMessageException(
        'Unexpected kind of message: ${message.runtimeType}');
  }
}
