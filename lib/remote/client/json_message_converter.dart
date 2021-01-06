import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:lets_play_cities/base/data/word_result.dart';
import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:lets_play_cities/remote/model/incoming_models.dart';
import 'package:lets_play_cities/remote/model/outgoing_models.dart';
import 'package:lets_play_cities/remote/client/socket_api.dart';

import '../model/profile_info.dart';
import '../model/utils.dart';

class JsonMessageConverter implements MessageConverter {
  @override
  IncomingMessage decode(String data) {
    Map<String, dynamic> jsonMessage = jsonDecode(data);
    final action = jsonMessage['action'];
    if (action == null) {
      throw UnknownMessageException('No action provided!');
    }

    switch (action) {
      case 'logged_in':
        return LoggedInMessage(newerBuild: jsonMessage['newerBuild']);
      case 'login_error':
        return BannedMessage(banReason: jsonMessage['banReason']);
      case 'join':
        return JoinMessage(
          canReceiveMessages: jsonMessage['canReceiveMessages'],
          youStarter: jsonMessage['youStarter'],
          opponent: ProfileInfo(
            userId: jsonMessage['oppUid'],
            login: jsonMessage['login'],
            banStatus: BanStatus.notBanned,
            friendshipStatus:
                FriendshipStatusExt.fromString(jsonMessage['friendshipStatus']),
            role: Role.regular,
            authType: AuthTypeExtension.fromString(jsonMessage['authType']),
            lastVisitDate: DateTime.now(),
            pictureUrl: getPictureUrlOrNull(
                jsonMessage['oppUid'], jsonMessage['pictureHash']),
          ),
        );
      case 'word':
        return WordMessage(
          ownerId: jsonMessage['ownerId'],
          word: jsonMessage['word'],
          result: WordResultExtensions.fromString(jsonMessage['result']),
        );
      case 'msg':
        return ChatMessage(
          message: jsonMessage['msg'],
          ownerId: jsonMessage['ownerId'],
        );
      case 'timeout':
        return TimeoutMessage();
      // TODO: Implement another message types
      default:
        throw UnknownMessageException('Unexpected kind of message: $action');
    }
  }

  @override
  String encode(OutgoingMessage message) => jsonEncode(_encodeToJson(message));

  Map<String, dynamic> _encodeToJson(OutgoingMessage message) {
    if (message is LogInMessage) {
      return {
        'action': 'login',
        'version': message.version,
        'clientBuild': message.clientBuild,
        'clientVersion': message.clientVersion,
        'canReceiveMessages': message.canReceiveMessages,
        'firebaseToken': message.firebaseToken,
        'uid': message.uid,
        'hash': message.hash,
      };
    } else if (message is PlayMessage) {
      return {
        'action': 'play',
        'mode': describeEnum(message.mode),
        'oppUid': message.oppUid,
      };
    } else if (message is OutgoingWordMessage) {
      return {
        'action': 'word',
        'word': message.word,
      };
    } else if (message is OutgoingChatMessage) {
      return {
        'action': 'msg',
        'msg': message.msg,
      };
    }
    throw UnknownMessageException(
        'Unexpected kind of message: ${message.runtimeType}');
  }
}
