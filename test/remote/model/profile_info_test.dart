import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/remote/model/auth_type.dart';
import 'package:lets_play_cities/remote/model/profile_info.dart';

void main() {
  final config = AppConfig.forHost('lps.test');

  // A profile as the REST API returns it from GET /user/{id}.
  const json = {
    'login': 'Player',
    'userId': 42,
    'friendshipStatus': 'friends',
    'banStatus': 'notBanned',
    'role': 'REGULAR_USER',
    'authType': 'Google',
    'lastVisitDate': 1700000000000,
    'pictureHash': 'abc123',
  };

  ProfileInfo parse(Map<String, Object?> json) =>
      ProfileInfo.fromJson(config, json);

  test('fromJson reads a full profile', () {
    expect(
      parse(json),
      ProfileInfo(
        userId: 42,
        login: 'Player',
        pictureUrl: 'https://lps.test:8443/user/42/picture?hash=abc123',
        role: Role.regular,
        lastVisitDate: DateTime.fromMillisecondsSinceEpoch(1700000000000),
        banStatus: BanStatus.notBanned,
        friendshipStatus: FriendshipStatus.friends,
        authType: AuthType.google,
      ),
    );
  });

  test('lastVisitDate is in epoch milliseconds', () {
    expect(
      parse(json).lastVisitDate
          .isAtSameMomentAs(DateTime.utc(2023, 11, 14, 22, 13, 20)),
      isTrue,
    );
  });

  test('a profile without pictureHash has no picture', () {
    expect(parse({...json}..remove('pictureHash')).pictureUrl, isNull);
  });

  group('role', () {
    const roles = {
      'REGULAR_USER': Role.regular,
      'ADMIN': Role.admin,
      'BANNED_USER': Role.banned,
    };
    for (final MapEntry(key: wire, value: role) in roles.entries) {
      test('"$wire"', () {
        expect(parse({...json, 'role': wire}).role, role);
      });
    }

    // The sign-up response names roles differently ('ready', 'admin').
    test('in the sign-up format is rejected', () {
      expect(() => parse({...json, 'role': 'ready'}), throwsA(isA<String>()));
    });
  });

  group('banStatus', () {
    const statuses = {
      'notBanned': BanStatus.notBanned,
      'inputBan': BanStatus.inputBan,
      'outputBan': BanStatus.outputBan,
      'owner': BanStatus.owner,
    };
    for (final MapEntry(key: wire, value: status) in statuses.entries) {
      test('"$wire"', () {
        expect(parse({...json, 'banStatus': wire}).banStatus, status);
      });
    }

    test('unknown value throws a StateError', () {
      expect(
        () => parse({...json, 'banStatus': 'NOT_BANNED'}),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('friendshipStatus', () {
    const statuses = {
      'notFriends': FriendshipStatus.notFriends,
      'friends': FriendshipStatus.friends,
      'inputRequest': FriendshipStatus.inputRequest,
      'outputRequest': FriendshipStatus.outputRequest,
      'owner': FriendshipStatus.owner,
    };
    for (final MapEntry(key: wire, value: status) in statuses.entries) {
      test('"$wire"', () {
        expect(
          parse({...json, 'friendshipStatus': wire}).friendshipStatus,
          status,
        );
      });
    }
  });

  test('authType is read by its full name only', () {
    expect(
      parse({...json, 'authType': 'Odnoklassniki'}).authType,
      AuthType.odnoklassniki,
    );
    expect(() => parse({...json, 'authType': 'ok'}), throwsA(isA<String>()));
  });
}
