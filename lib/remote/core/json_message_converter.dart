import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:lets_play_cities/base/data/word_result.dart';
import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:lets_play_cities/remote/model/server_messages.dart';
import 'package:lets_play_cities/remote/model/client_messages.dart';
import 'package:lets_play_cities/remote/client/socket_api.dart';

import '../model/profile_info.dart';
import '../model/utils.dart';

class JsonMessageConverter
    implements MessageConverter<ServerMessage, ClientMessage> {
  @override
  ServerMessage decode(String data) {
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
      case 'leave':
        return DisconnectedMessage();
      case 'fm_request':
        return InvitationResponseMessage(
          login: jsonMessage['login'],
          oppId: jsonMessage['oppUid'],
          result: InviteResultTypeExt.fromString(jsonMessage['result']),
        );
      default:
        throw UnknownMessageException('Unexpected kind of message: $action');
    }
  }

  @override
  String encode(ClientMessage message) => jsonEncode(_encodeToJson(message));

  Map<String, dynamic> _encodeToJson(ClientMessage message) {
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
    } else if (message is InvitationResultMessage) {
      return {
        'action': 'fm_req_result',
        'oppUid': message.oppId,
        'result': message.result.code,
      };
    }
    throw UnknownMessageException(
        'Unexpected kind of message: ${message.runtimeType}');
  }
}

extension InvitationResultExt on InvitationResult {
  int get code {
    switch (this) {
      case InvitationResult.accept:
        return 1;
      case InvitationResult.decline:
        return 2;
      default:
        throw UnknownMessageException.badEnumType(this);
    }
  }
}

extension InviteResultTypeExt on InvitationResponseMessage {
  static InviteResultType fromString(String s) {
    switch (s) {
      case 'BUSY':
        return InviteResultType.busy;
      case 'NOT_FRIEND':
        return InviteResultType.notFriend;
      case 'DENIED':
        return InviteResultType.denied;
      case 'NO_USER':
        return InviteResultType.noUser;
      default:
        throw UnknownMessageException.badEnumType(s);
    }
  }
}
