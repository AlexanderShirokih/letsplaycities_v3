import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/remote/auth/auth_api.dart';
import 'package:lets_play_cities/remote/auth/token_store.dart';
import 'package:lets_play_cities/remote/client/api_dio.dart';
import 'package:lets_play_cities/remote/client/api_exception.dart';
import 'package:lets_play_cities/remote/model/lps_user.dart';

import '../fake_server.dart';

/// The user of `testdata/protocol/server-welcome.json`
const userJson = {
  'id': 14397,
  'name': 'Мария',
  'avatarHash': '3f7a9c1be2d84a55',
  'provider': 'google',
  'lastSeenAt': 1762560000000,
};

void main() {
  final config = AppConfig.forHost('lps.test');

  late FakeServer server;
  late MemoryTokenStore tokens;
  late AuthApi api;

  setUp(() {
    server = FakeServer();
    tokens = MemoryTokenStore();
    api = AuthApi(
      createApiDio(config, tokens, onError: (e, s) => fail('$e'))
        ..httpClientAdapter = server,
    );
  });

  test('native sends deviceId and name', () async {
    server.on('POST', '/v1/auth/native', 200, {
      'token': 'new-token',
      'user': userJson,
    });

    final result = await api.native('device-1', 'Мария');

    expect(server.calls, ['POST /v1/auth/native']);
    expect(server.bodyOf('POST', '/v1/auth/native'), {
      'deviceId': 'device-1',
      'name': 'Мария',
    });
    expect(result.token, 'new-token');
    expect(result.user.id, 14397);
  });

  test('social sends provider, token and name', () async {
    server.on('POST', '/v1/auth/social', 200, {
      'token': 'new-token',
      'user': userJson,
    });

    final result = await api.social('vk', 'vk-token', 'Мария');

    expect(server.bodyOf('POST', '/v1/auth/social'), {
      'provider': 'vk',
      'token': 'vk-token',
      'name': 'Мария',
    });
    expect(result.token, 'new-token');
  });

  test('logout sends the token it revokes', () async {
    await tokens.write('secret');
    server.on('POST', '/v1/auth/logout', 204);

    await api.logout();

    expect(server.calls, ['POST /v1/auth/logout']);
    expect(server.requests.single.headers['Authorization'], 'Bearer secret');
  });

  test('me reads the signed-in user', () async {
    server.on('GET', '/v1/me', 200, userJson);

    final user = await api.me();

    expect(user.name, 'Мария');
  });

  test('updateMe sends only the given fields', () async {
    server.on('PATCH', '/v1/me', 200, userJson);

    await api.updateMe(fcmToken: 'fcm-1');

    expect(server.bodyOf('PATCH', '/v1/me'), {'fcmToken': 'fcm-1'});
  });

  test('an error answer throws ApiException with its code', () async {
    server.fail('POST', '/v1/auth/native', 400, 'bad_name');

    await expectLater(
      api.native('device-1', ''),
      throwsA(
        isA<ApiException>()
            .having((e) => e.code, 'code', 'bad_name')
            .having((e) => e.message, 'message', 'Server says bad_name'),
      ),
    );
  });

  group('LpsUser', () {
    test('reads the protocol user', () {
      final user = LpsUser.fromJson(userJson);

      expect(
        user,
        LpsUser(
          id: 14397,
          name: 'Мария',
          avatarHash: '3f7a9c1be2d84a55',
          provider: 'google',
          lastSeenAt: DateTime.fromMillisecondsSinceEpoch(1762560000000),
        ),
      );
    });

    test('avatar url carries the hash, no hash means no avatar', () {
      final user = LpsUser.fromJson(userJson);
      final noAvatar = LpsUser.fromJson({...userJson, 'avatarHash': null});

      expect(
        user.avatarUrl(config),
        'https://lps.test:443/v1/avatars/14397?v=3f7a9c1be2d84a55',
      );
      expect(noAvatar.avatarUrl(config), isNull);
    });

    test('is online for 5 minutes after lastSeenAt', () {
      final user = LpsUser.fromJson(userJson);
      final seen = user.lastSeenAt;

      expect(user.isOnline(seen.add(const Duration(minutes: 4))), isTrue);
      expect(user.isOnline(seen.add(const Duration(minutes: 5))), isFalse);
    });
  });
}
