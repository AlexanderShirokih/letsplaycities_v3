import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/base/data/word_result.dart';
import 'package:lets_play_cities/remote/core/json_message_converter.dart';
import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:lets_play_cities/remote/model/auth_type.dart';
import 'package:lets_play_cities/remote/model/client_messages.dart';
import 'package:lets_play_cities/remote/model/profile_info.dart';
import 'package:lets_play_cities/remote/model/server_messages.dart';

// These tests pin the client side of the game socket protocol: the JSON the
// server sends and the JSON the client sends back. Every expectation is a
// literal, so renaming an enum constant must not change what goes over the
// wire.

class _UnsupportedClientMessage extends ClientMessage {
  const _UnsupportedClientMessage();
}

void main() {
  final converter = JsonMessageConverter(AppConfig.forHost('lps.test'));

  ServerMessage decode(Map<String, Object?> json) =>
      converter.decode(jsonEncode(json));

  Map<String, dynamic> encode(ClientMessage message) =>
      jsonDecode(converter.encode(message));

  group('decodes the server action', () {
    test('logged_in with the newest client build', () {
      expect(
        converter.decode('{"action":"logged_in","newerBuild":512}'),
        const LoggedInMessage(newerBuild: 512),
      );
    });

    test('login_error with a ban reason', () {
      expect(
        converter.decode('{"action":"login_error","banReason":"Spam"}'),
        const BannedMessage(banReason: 'Spam'),
      );
    });

    test('login_error without a ban reason', () {
      expect(
        converter.decode('{"action":"login_error"}'),
        const BannedMessage(),
      );
    });

    test('timeout', () {
      expect(converter.decode('{"action":"timeout"}'), isA<TimeoutMessage>());
    });

    test('leave as a disconnect of the opponent', () {
      expect(
        converter.decode('{"action":"leave"}'),
        isA<DisconnectedMessage>(),
      );
    });

    test('msg from the opponent', () {
      expect(
        converter.decode('{"action":"msg","msg":"Привет!","ownerId":7}'),
        const ChatMessage(message: 'Привет!', ownerId: 7),
      );
    });

    group('join', () {
      final joinedAt = DateTime(2024, 3, 15, 10, 30);
      const json = {
        'action': 'join',
        'canReceiveMessages': true,
        'youStarter': false,
        'oppUid': 42,
        'login': 'Opponent',
        'friendshipStatus': 'friends',
        'authType': 'Google',
        'pictureHash': 'abc123',
      };

      ServerMessage decodeJoin(Map<String, Object?> json) =>
          withClock(Clock.fixed(joinedAt), () => decode(json));

      ProfileInfo opponentOf(ServerMessage message) =>
          (message as JoinMessage).opponent;

      test('builds the opponent profile with a picture URL from the hash', () {
        expect(
          decodeJoin(json),
          JoinMessage(
            canReceiveMessages: true,
            youStarter: false,
            opponent: ProfileInfo(
              userId: 42,
              login: 'Opponent',
              pictureUrl: 'https://lps.test:443/v1/avatars/42?v=abc123',
              role: Role.regular,
              lastVisitDate: joinedAt,
              banStatus: BanStatus.notBanned,
              friendshipStatus: FriendshipStatus.friends,
              authType: AuthType.google,
            ),
          ),
        );
      });

      test('without pictureHash the opponent has no picture', () {
        final message = decodeJoin({...json}..remove('pictureHash'));

        expect(opponentOf(message).pictureUrl, isNull);
      });

      test('with an empty pictureHash the opponent has no picture', () {
        final message = decodeJoin({...json, 'pictureHash': ''});

        expect(opponentOf(message).pictureUrl, isNull);
      });

      const friendshipStatuses = {
        'notFriends': FriendshipStatus.notFriends,
        'friends': FriendshipStatus.friends,
        'inputRequest': FriendshipStatus.inputRequest,
        'outputRequest': FriendshipStatus.outputRequest,
        'owner': FriendshipStatus.owner,
      };
      for (final MapEntry(key: wire, value: status)
          in friendshipStatuses.entries) {
        test('friendshipStatus "$wire"', () {
          final message = decodeJoin({...json, 'friendshipStatus': wire});

          expect(opponentOf(message).friendshipStatus, status);
        });
      }

      const authTypes = {
        'Native': AuthType.native,
        'Google': AuthType.google,
        'Vkontakte': AuthType.vkontakte,
        'Odnoklassniki': AuthType.odnoklassniki,
        'Facebook': AuthType.facebook,
      };
      for (final MapEntry(key: wire, value: authType) in authTypes.entries) {
        test('authType "$wire" (full name)', () {
          final message = decodeJoin({...json, 'authType': wire});

          expect(opponentOf(message).authType, authType);
        });
      }
    });

    const wordResults = {
      'RECEIVED': WordResult.received,
      'ACCEPTED': WordResult.accepted,
      'ALREADY': WordResult.already,
      'NO_WORD': WordResult.noWord,
      'WRONG_MOVE': WordResult.wrongMove,
      'UNKNOWN': WordResult.unknown,
    };
    for (final MapEntry(key: wire, value: result) in wordResults.entries) {
      test('word with result "$wire"', () {
        expect(
          decode({
            'action': 'word',
            'ownerId': 7,
            'word': 'москва',
            'result': wire,
          }),
          WordMessage(result: result, word: 'москва', ownerId: 7),
        );
      });
    }

    const inviteResults = {
      'BUSY': InviteResultType.busy,
      'NOT_FRIEND': InviteResultType.notFriend,
      'DENIED': InviteResultType.denied,
      'NO_USER': InviteResultType.noUser,
    };
    for (final MapEntry(key: wire, value: result) in inviteResults.entries) {
      test('fm_request with result "$wire"', () {
        expect(
          decode({
            'action': 'fm_request',
            'login': 'Friend',
            'oppUid': 9,
            'result': wire,
          }),
          InvitationResponseMessage(login: 'Friend', oppId: 9, result: result),
        );
      });
    }

    test('fm_request without the opponent login and ID', () {
      expect(
        converter.decode('{"action":"fm_request","result":"NO_USER"}'),
        const InvitationResponseMessage(
          login: null,
          oppId: null,
          result: InviteResultType.noUser,
        ),
      );
    });
  });

  group('rejects a server message', () {
    test('without an action', () {
      expect(
        () => converter.decode('{"newerBuild":512}'),
        throwsA(isA<UnknownMessageException>()),
      );
    });

    test('with an unknown action', () {
      expect(
        () => converter.decode('{"action":"banlist"}'),
        throwsA(isA<UnknownMessageException>()),
      );
    });

    test('with an unknown fm_request result', () {
      expect(
        () => converter.decode('{"action":"fm_request","result":"busy"}'),
        throwsA(isA<UnknownMessageException>()),
      );
    });
  });

  // Current behaviour, pinned as is: these enum parsers do not throw the
  // UnknownMessageException that MessageConverter.decode documents.
  group('an unknown enum value in a server message', () {
    test('word result throws a String', () {
      expect(
        () => decode({
          'action': 'word',
          'ownerId': 7,
          'word': 'москва',
          'result': 'accepted',
        }),
        throwsA(isA<String>()),
      );
    });

    final join = {
      'action': 'join',
      'canReceiveMessages': true,
      'youStarter': true,
      'oppUid': 42,
      'login': 'Opponent',
      'friendshipStatus': 'friends',
      'authType': 'Native',
    };

    test('short authType name in join throws a String', () {
      expect(() => decode({...join, 'authType': 'nv'}), throwsA(isA<String>()));
    });

    test('friendshipStatus in join throws a StateError', () {
      expect(
        () => decode({...join, 'friendshipStatus': 'FRIENDS'}),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('encodes the client message', () {
    test('login with protocol version 5', () {
      expect(
        encode(
          const LogInMessage(
            clientBuild: 401,
            clientVersion: '1.4.1',
            canReceiveMessages: true,
            firebaseToken: 'fcm-token',
            uid: 42,
            hash: 'access-hash',
          ),
        ),
        {
          'action': 'login',
          'version': 5,
          'clientBuild': 401,
          'clientVersion': '1.4.1',
          'canReceiveMessages': true,
          'firebaseToken': 'fcm-token',
          'uid': 42,
          'hash': 'access-hash',
        },
      );
    });

    test('play with a random opponent', () {
      expect(
        encode(const PlayMessage(mode: PlayMode.randomPair, oppUid: null)),
        {'action': 'play', 'mode': 'RANDOM_PAIR', 'oppUid': null},
      );
    });

    test('play with a friend', () {
      expect(encode(const PlayMessage(mode: PlayMode.friend, oppUid: 9)), {
        'action': 'play',
        'mode': 'FRIEND',
        'oppUid': 9,
      });
    });

    test('word', () {
      expect(encode(const OutgoingWordMessage(word: 'москва')), {
        'action': 'word',
        'word': 'москва',
      });
    });

    test('msg', () {
      expect(encode(const OutgoingChatMessage(msg: 'Привет!')), {
        'action': 'msg',
        'msg': 'Привет!',
      });
    });

    test('accepted invitation as result 1', () {
      expect(
        encode(
          const InvitationResultMessage(
            result: InvitationResult.accept,
            oppId: 9,
          ),
        ),
        {'action': 'fm_req_result', 'oppUid': 9, 'result': 1},
      );
    });

    test('declined invitation as result 2', () {
      expect(
        encode(
          const InvitationResultMessage(
            result: InvitationResult.decline,
            oppId: 9,
          ),
        ),
        {'action': 'fm_req_result', 'oppUid': 9, 'result': 2},
      );
    });

    test('of an unsupported kind by throwing UnknownMessageException', () {
      expect(
        () => converter.encode(const _UnsupportedClientMessage()),
        throwsA(isA<UnknownMessageException>()),
      );
    });
  });
}
