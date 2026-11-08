import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/remote/account_manager_impl.dart';
import 'package:lets_play_cities/remote/api_repository_factory.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/auth/auth_api.dart';
import 'package:lets_play_cities/remote/auth/token_store.dart';
import 'package:lets_play_cities/remote/client/api_dio.dart';
import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:lets_play_cities/remote/model/cloud_messages.dart';
import 'package:lets_play_cities/remote/model/cloud_messaging_service.dart';
import 'package:lets_play_cities/remote/social/social_network_data.dart';
import 'package:lets_play_cities/remote/social/social_networks_service.dart';
import 'package:lets_play_cities/utils/error_logger.dart';

import 'auth/auth_api_test.dart' show userJson;
import 'fake_lps_api_client.dart';
import 'fake_server.dart';

class _FakePreferences extends Fake implements GamePreferences {
  @override
  bool get onlineChatEnabled => true;
}

class _FakeSocialNetworks extends Fake implements SocialNetworksService {
  /// When set, [login] throws it.
  Object? loginError;

  String pictureUri = 'https://pictures.test/alice.png';

  @override
  Future<SocialNetworkData> login(AuthType networkType) async {
    final error = loginError;
    if (error != null) throw error;

    return SocialNetworkData(
      login: 'Alice',
      authType: networkType,
      pictureUri: pictureUri,
      accessToken: 'network-token',
      snUID: 'network-uid',
    );
  }

  @override
  Future<String> getDeviceId() async => 'device-1';
}

class _FakeMessaging implements CloudMessagingService {
  String token = 'fcm-1';
  final refreshes = StreamController<String>.broadcast();

  @override
  Future<String> getUserToken() async => token;

  @override
  Stream<String> get tokenRefreshes => refreshes.stream;

  @override
  Stream<IncomingCloudMessage> get messages => const Stream.empty();
}

class _RecordingLogger implements ErrorLogger {
  final errors = <Object>[];

  @override
  void error(Object error, StackTrace stackTrace) => errors.add(error);

  @override
  void log(String message) {}
}

class _FakeRepository extends Fake implements ApiRepository {
  final pictures = <String>[];

  @override
  Future<void> updatePictureFromURL(String pictureURL) async =>
      pictures.add(pictureURL);
}

class _FakeFactory extends Fake implements ApiRepositoryFactory {
  _FakeFactory(this.pictureConfig, this.tokens, this.repository);

  @override
  final AppConfig pictureConfig;

  @override
  final TokenStore tokens;

  final _FakeRepository repository;

  @override
  final cache = ApiRepositoryCacheHolder();

  @override
  ApiRepository forUser([int userId = 0]) => repository;
}

Map<String, Object?> _auth(String token, {Object? avatarHash = 'hash'}) => {
  'token': token,
  'user': {...userJson, 'avatarHash': avatarHash},
};

void main() {
  final config = AppConfig.forHost('lps.test');

  late FakeServer server;
  late MemoryTokenStore tokens;
  late _FakeFactory factory;
  late _FakeSocialNetworks social;
  late _FakeMessaging messaging;
  late _RecordingLogger logger;
  late DateTime now;
  late AccountManagerImpl manager;

  setUp(() {
    server = FakeServer();
    tokens = MemoryTokenStore();
    factory = _FakeFactory(config, tokens, _FakeRepository());
    social = _FakeSocialNetworks();
    messaging = _FakeMessaging();
    logger = _RecordingLogger();
    now = DateTime(2026, 11, 8, 12);

    final dio = createApiDio(
      config,
      tokens,
      onSignedOut: factory.cache.clear,
      onError: logger.error,
    )..httpClientAdapter = server;

    manager = AccountManagerImpl(
      preferences: _FakePreferences(),
      apiRepositories: factory,
      auth: AuthApi(dio),
      socialNetworks: social,
      messaging: messaging,
      logger: logger,
      clock: () => now,
    );

    server
      ..on('PATCH', '/v1/me', 200, userJson)
      ..on('GET', '/v1/me', 200, userJson)
      ..on('POST', '/v1/auth/logout', 204);
  });

  group('silent native', () {
    test(
      'silent native with bad_name returns null and makes one request',
      () async {
        server.fail('POST', '/v1/auth/native', 400, 'bad_name');

        final account = await manager.trySilentNative();

        expect(account, isNull);
        expect(server.calls, ['POST /v1/auth/native']);
        expect(server.bodyOf('POST', '/v1/auth/native'), {
          'deviceId': 'device-1',
          'name': '',
        });
        expect(await tokens.read(), isNull);
      },
    );

    test('returns null without the network', () async {
      server.offline = true;

      expect(await manager.trySilentNative(), isNull);
    });

    test('signs in the account of this device', () async {
      server.on('POST', '/v1/auth/native', 200, _auth('device-token'));

      final account = await manager.trySilentNative();

      expect(account!.userId, 14397);
      expect(await tokens.read(), 'device-token');
    });
  });

  group('sign-in', () {
    test('native sends the trimmed name and keeps the token', () async {
      server.on('POST', '/v1/auth/native', 200, _auth('new-token'));

      final account = await manager.signInNative('  Мария ');

      expect(server.bodyOf('POST', '/v1/auth/native'), {
        'deviceId': 'device-1',
        'name': 'Мария',
      });
      expect(account.name, 'Мария');
      expect(account.avatarUrl, 'https://lps.test:443/v1/avatars/14397?v=hash');
      expect(account.canReceiveMessages, isTrue);
      expect(await tokens.read(), 'new-token');
    });

    test('social maps vkontakte to vk', () async {
      server.on('POST', '/v1/auth/social', 200, _auth('vk-session'));

      await manager.signInSocial(AuthType.vkontakte);

      expect(server.bodyOf('POST', '/v1/auth/social'), {
        'provider': 'vk',
        'token': 'network-token',
        'name': 'Alice',
      });
      expect(await tokens.read(), 'vk-session');
    });

    test('social google sends provider google', () async {
      server.on('POST', '/v1/auth/social', 200, _auth('google-session'));

      await manager.signInSocial(AuthType.google);

      expect(
        (server.bodyOf('POST', '/v1/auth/social')! as Map)['provider'],
        'google',
      );
    });

    test('a cancelled network sign-in sends nothing', () async {
      social.loginError = AuthorizationException('cancelled');

      await expectLater(
        manager.signInSocial(AuthType.google),
        throwsA(isA<AuthorizationException>()),
      );
      expect(server.calls, isEmpty);
    });

    test(
      'social picture is uploaded only for an account without avatar',
      () async {
        server.on(
          'POST',
          '/v1/auth/social',
          200,
          _auth('t1', avatarHash: null),
        );
        await manager.signInSocial(AuthType.vkontakte);

        server.on('POST', '/v1/auth/social', 200, _auth('t2'));
        await manager.signInSocial(AuthType.vkontakte);

        expect(factory.repository.pictures, [
          'https://pictures.test/alice.png',
        ]);
      },
    );

    test('the signed-in account is served without GET /v1/me', () async {
      server.on('POST', '/v1/auth/native', 200, _auth('new-token'));
      final signedIn = await manager.signInNative('Мария');

      expect(await manager.getLastSignedInAccount(), signedIn);
      expect(server.calls, isNot(contains('GET /v1/me')));
    });

    test('a token dropped by another request ends the account', () async {
      server.on('POST', '/v1/auth/native', 200, _auth('new-token'));
      await manager.signInNative('Мария');

      // What the interceptor does on a 401 of any request
      await tokens.clear();

      expect(await manager.getLastSignedInAccount(), isNull);
      expect(server.calls, isNot(contains('GET /v1/me')));
    });

    test('sign-in drops the API cache of the previous account', () async {
      factory.cache.cachedFriendsList = [friend(10)];
      server.on('POST', '/v1/auth/native', 200, _auth('new-token'));

      await manager.signInNative('Мария');

      expect(factory.cache.cachedFriendsList, isNull);
    });
  });

  group('fcm token', () {
    setUp(() {
      server.on('POST', '/v1/auth/native', 200, _auth('new-token'));
    });

    test('fcm token is patched after sign-in', () async {
      await manager.signInNative('Мария');

      expect(server.bodyOf('PATCH', '/v1/me'), {'fcmToken': 'fcm-1'});
    });

    test('an empty fcm token is not sent', () async {
      messaging.token = '';

      await manager.signInNative('Мария');

      expect(server.calls, isNot(contains('PATCH /v1/me')));
    });

    test('a failed patch does not fail the sign-in', () async {
      server.fail('PATCH', '/v1/me', 500, 'internal');

      final account = await manager.signInNative('Мария');

      expect(account.userId, 14397);
      expect(logger.errors, isNotEmpty);
    });

    test('a refreshed token is patched while signed in', () async {
      await manager.signInNative('Мария');

      messaging.refreshes.add('fcm-2');
      await pumpEventQueue();

      expect(server.bodyOf('PATCH', '/v1/me'), {'fcmToken': 'fcm-2'});

      await manager.signOut();
      server.requests.clear();
      messaging.refreshes.add('fcm-3');
      await pumpEventQueue();

      expect(server.calls, isEmpty);
    });
  });

  group('last signed-in account', () {
    test('without a token there is no account and no request', () async {
      expect(await manager.getLastSignedInAccount(), isNull);
      expect(server.calls, isEmpty);
    });

    test('is read from GET /v1/me and kept for 5 minutes', () async {
      await tokens.write('stored');

      final account = await manager.getLastSignedInAccount();
      now = now.add(const Duration(minutes: 4));
      await manager.getLastSignedInAccount();

      expect(account!.userId, 14397);
      expect(server.calls.where((c) => c == 'GET /v1/me'), hasLength(1));

      now = now.add(const Duration(minutes: 2));
      await manager.getLastSignedInAccount();

      expect(server.calls.where((c) => c == 'GET /v1/me'), hasLength(2));
    });

    test(
      'getLastSignedInAccount returns null on 401 and clears token',
      () async {
        await tokens.write('revoked');
        server.fail('GET', '/v1/me', 401, 'unauthorized');

        expect(await manager.getLastSignedInAccount(), isNull);
        expect(await tokens.read(), isNull);
      },
    );

    test('a network error is not kept', () async {
      await tokens.write('stored');
      server.offline = true;

      await expectLater(manager.getLastSignedInAccount(), throwsA(anything));

      server.offline = false;
      expect(await manager.getLastSignedInAccount(), isNotNull);
    });
  });

  group('sign-out', () {
    setUp(() async {
      server.on('POST', '/v1/auth/native', 200, _auth('session'));
      await manager.signInNative('Мария');
      factory.cache.cachedFriendsList = [friend(10)];
      server.requests.clear();
    });

    test(
      'signOut calls logout then clears token even if logout fails',
      () async {
        server.fail('POST', '/v1/auth/logout', 500, 'internal');

        await manager.signOut();

        expect(server.calls, ['POST /v1/auth/logout']);
        expect(
          server.requests.single.headers['Authorization'],
          'Bearer session',
        );
        expect(await tokens.read(), isNull);
        expect(factory.cache.cachedFriendsList, isNull);
        expect(await manager.getLastSignedInAccount(), isNull);
      },
    );

    test('signOut without the network still signs out', () async {
      server.offline = true;

      await manager.signOut();

      expect(await tokens.read(), isNull);
    });
  });
}
