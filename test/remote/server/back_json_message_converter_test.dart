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
import 'package:lets_play_cities/remote/server/back_json_message_converter.dart';

// These tests pin the local (LAN) game server side of the socket protocol and
// check that it speaks the same JSON as the client converter. Every literal
// is what goes over the wire, so renaming an enum constant must not change it.

const _wordResults = {
  'RECEIVED': WordResult.received,
  'ACCEPTED': WordResult.accepted,
  'ALREADY': WordResult.already,
  'NO_WORD': WordResult.noWord,
  'WRONG_MOVE': WordResult.wrongMove,
  'UNKNOWN': WordResult.unknown,
};

const _authTypes = {
  'Native': AuthType.native,
  'Google': AuthType.google,
  'Vkontakte': AuthType.vkontakte,
  'Odnoklassniki': AuthType.odnoklassniki,
  'Facebook': AuthType.facebook,
};

const _friendshipStatuses = {
  'notFriends': FriendshipStatus.notFriends,
  'friends': FriendshipStatus.friends,
  'inputRequest': FriendshipStatus.inputRequest,
  'outputRequest': FriendshipStatus.outputRequest,
  'owner': FriendshipStatus.owner,
};

void main() {
  final server = BackJsonMessageConverter();
  final client = JsonMessageConverter(AppConfig.forHost('lps.test'));

  Map<String, dynamic> encode(ServerMessage message) =>
      jsonDecode(server.encode(message));

  ProfileInfo opponent({
    String? pictureUrl,
    Role role = Role.regular,
    BanStatus banStatus = BanStatus.notBanned,
    FriendshipStatus friendshipStatus = FriendshipStatus.notFriends,
    AuthType authType = AuthType.native,
    required DateTime lastVisitDate,
  }) => ProfileInfo(
    userId: 42,
    login: 'Opponent',
    pictureUrl: pictureUrl,
    role: role,
    lastVisitDate: lastVisitDate,
    banStatus: banStatus,
    friendshipStatus: friendshipStatus,
    authType: authType,
  );

  group('decodes the client action', () {
    const login = {
      'action': 'login',
      'version': 5,
      'clientBuild': 401,
      'clientVersion': '1.4.1',
      'canReceiveMessages': true,
      'firebaseToken': 'fcm-token',
      'uid': 42,
      'hash': 'access-hash',
    };

    test('login with protocol version 5', () {
      final message = server.decode(jsonEncode(login));

      expect(
        message,
        isA<LogInMessage>()
            .having((m) => m.uid, 'uid', 42)
            .having((m) => m.clientBuild, 'clientBuild', 401)
            .having((m) => m.clientVersion, 'clientVersion', '1.4.1')
            .having((m) => m.canReceiveMessages, 'canReceiveMessages', true),
      );
    });

    test('login replaces the client access hash and drops the FCM token', () {
      final message = server.decode(jsonEncode(login)) as LogInMessage;

      expect(message.hash, 'remote_hash');
      expect(message.firebaseToken, '');
    });

    for (final version in [4, 1]) {
      test('login with protocol version $version is rejected', () {
        expect(
          () => server.decode(jsonEncode({...login, 'version': version})),
          throwsA(isA<RemoteException>()),
        );
      });
    }

    test('login without a protocol version is rejected', () {
      expect(
        () => server.decode(jsonEncode({...login}..remove('version'))),
        throwsA(isA<RemoteException>()),
      );
    });

    test('play with a random opponent', () {
      expect(
        server.decode('{"action":"play","mode":"RANDOM_PAIR","oppUid":null}'),
        const PlayMessage(mode: PlayMode.randomPair, oppUid: null),
      );
    });

    test('play with a friend', () {
      expect(
        server.decode('{"action":"play","mode":"FRIEND","oppUid":9}'),
        const PlayMessage(mode: PlayMode.friend, oppUid: 9),
      );
    });

    test('word', () {
      expect(
        server.decode('{"action":"word","word":"москва"}'),
        const OutgoingWordMessage(word: 'москва'),
      );
    });

    test('msg', () {
      expect(
        server.decode('{"action":"msg","msg":"Привет!"}'),
        const OutgoingChatMessage(msg: 'Привет!'),
      );
    });
  });

  group('rejects a client message', () {
    test('without an action', () {
      expect(
        () => server.decode('{"word":"москва"}'),
        throwsA(isA<UnknownMessageException>()),
      );
    });

    test('with an action the LAN server does not handle', () {
      expect(
        () => server.decode('{"action":"fm_req_result","oppUid":9,"result":1}'),
        throwsA(isA<UnknownMessageException>()),
      );
    });

    // Current behaviour, pinned as is: the play mode is parsed by its exact
    // constant name and an unknown one is not an UnknownMessageException.
    test('with an unknown play mode', () {
      expect(
        () => server.decode('{"action":"play","mode":"randomPair"}'),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('encodes the server message', () {
    test('logged_in with the newest client build', () {
      expect(encode(const LoggedInMessage(newerBuild: 512)), {
        'action': 'logged_in',
        'newerBuild': 512,
      });
    });

    test('login_error with a ban reason', () {
      expect(encode(const BannedMessage(banReason: 'Spam')), {
        'action': 'login_error',
        'banReason': 'Spam',
      });
    });

    test('login_error without a ban reason', () {
      expect(encode(const BannedMessage()), {
        'action': 'login_error',
        'banReason': null,
      });
    });

    test('join without the picture, role, ban status and visit date', () {
      expect(
        encode(
          JoinMessage(
            canReceiveMessages: true,
            youStarter: false,
            opponent: opponent(
              pictureUrl: 'https://lps.test:8443/user/42/picture?hash=abc',
              role: Role.admin,
              banStatus: BanStatus.outputBan,
              friendshipStatus: FriendshipStatus.inputRequest,
              authType: AuthType.vkontakte,
              lastVisitDate: DateTime(2024, 3, 15),
            ),
          ),
        ),
        {
          'action': 'join',
          'canReceiveMessages': true,
          'youStarter': false,
          'oppUid': 42,
          'login': 'Opponent',
          'friendshipStatus': 'inputRequest',
          'authType': 'Vkontakte',
        },
      );
    });

    for (final MapEntry(key: wire, value: authType) in _authTypes.entries) {
      test('join with authType "$wire" (full name)', () {
        final json = encode(
          JoinMessage(
            canReceiveMessages: true,
            youStarter: true,
            opponent: opponent(
              authType: authType,
              lastVisitDate: DateTime(2024),
            ),
          ),
        );

        expect(json['authType'], wire);
      });
    }

    for (final MapEntry(key: wire, value: status)
        in _friendshipStatuses.entries) {
      test('join with friendshipStatus "$wire"', () {
        final json = encode(
          JoinMessage(
            canReceiveMessages: true,
            youStarter: true,
            opponent: opponent(
              friendshipStatus: status,
              lastVisitDate: DateTime(2024),
            ),
          ),
        );

        expect(json['friendshipStatus'], wire);
      });
    }

    for (final MapEntry(key: wire, value: result) in _wordResults.entries) {
      test('word with result "$wire"', () {
        expect(
          encode(WordMessage(result: result, word: 'москва', ownerId: 7)),
          {'action': 'word', 'ownerId': 7, 'word': 'москва', 'result': wire},
        );
      });
    }

    test('msg', () {
      expect(encode(const ChatMessage(message: 'Привет!', ownerId: 7)), {
        'action': 'msg',
        'msg': 'Привет!',
        'ownerId': 7,
      });
    });

    test('timeout', () {
      expect(encode(TimeoutMessage()), {'action': 'timeout'});
    });

    test('opponent disconnect as leave', () {
      expect(encode(DisconnectedMessage()), {'action': 'leave'});
    });

    for (final message in <ServerMessage>[
      ConnectedMessage(),
      const InvitationResponseMessage(
        login: 'Friend',
        oppId: 9,
        result: InviteResultType.busy,
      ),
    ]) {
      test('${message.runtimeType} is not supported', () {
        expect(
          () => server.encode(message),
          throwsA(isA<UnknownMessageException>()),
        );
      });
    }
  });

  group('client to server round trip', () {
    ClientMessage roundTrip(ClientMessage message) =>
        server.decode(client.encode(message));

    test('login is accepted with its client data', () {
      expect(
        roundTrip(
          const LogInMessage(
            clientBuild: 401,
            clientVersion: '1.4.1',
            canReceiveMessages: false,
            firebaseToken: 'fcm-token',
            uid: 42,
            hash: 'access-hash',
          ),
        ),
        isA<LogInMessage>()
            .having((m) => m.uid, 'uid', 42)
            .having((m) => m.clientBuild, 'clientBuild', 401)
            .having((m) => m.clientVersion, 'clientVersion', '1.4.1')
            .having((m) => m.canReceiveMessages, 'canReceiveMessages', false),
      );
    });

    for (final message in const [
      PlayMessage(mode: PlayMode.randomPair, oppUid: null),
      PlayMessage(mode: PlayMode.friend, oppUid: 9),
    ]) {
      test('play in ${message.mode} mode', () {
        expect(roundTrip(message), message);
      });
    }

    test('word', () {
      const message = OutgoingWordMessage(word: 'санкт-петербург');
      expect(roundTrip(message), message);
    });

    test('msg', () {
      const message = OutgoingChatMessage(msg: 'Привет!');
      expect(roundTrip(message), message);
    });
  });

  group('server to client round trip', () {
    final now = DateTime(2024, 3, 15, 10, 30);

    ServerMessage roundTrip(ServerMessage message) => withClock(
      Clock.fixed(now),
      () => client.decode(server.encode(message)),
    );

    for (final (name, message) in const [
      ('logged_in', LoggedInMessage(newerBuild: 512)),
      ('login_error with a reason', BannedMessage(banReason: 'Spam')),
      ('login_error without a reason', BannedMessage()),
      ('msg', ChatMessage(message: 'Привет!', ownerId: 7)),
    ]) {
      test(name, () {
        expect(roundTrip(message), message);
      });
    }

    for (final result in WordResult.values) {
      test('word with result $result', () {
        final message = WordMessage(result: result, word: 'москва', ownerId: 7);

        expect(roundTrip(message), message);
      });
    }

    test('timeout', () {
      expect(roundTrip(TimeoutMessage()), isA<TimeoutMessage>());
    });

    test('leave', () {
      expect(roundTrip(DisconnectedMessage()), isA<DisconnectedMessage>());
    });

    // Covers every AuthType and every FriendshipStatus at least once.
    for (var i = 0; i < AuthType.values.length; i++) {
      final authType = AuthType.values[i];
      final status =
          FriendshipStatus.values[i % FriendshipStatus.values.length];
      test('join with $authType and $status', () {
        final message = JoinMessage(
          canReceiveMessages: false,
          youStarter: true,
          opponent: opponent(
            authType: authType,
            friendshipStatus: status,
            lastVisitDate: now,
          ),
        );

        expect(roundTrip(message), message);
      });
    }

    test('join loses the fields the wire does not carry', () {
      final message = roundTrip(
        JoinMessage(
          canReceiveMessages: true,
          youStarter: false,
          opponent: opponent(
            pictureUrl: 'https://lps.test:8443/user/42/picture?hash=abc',
            role: Role.admin,
            banStatus: BanStatus.outputBan,
            lastVisitDate: DateTime(2020),
          ),
        ),
      );

      expect((message as JoinMessage).opponent, opponent(lastVisitDate: now));
    });
  });
}
