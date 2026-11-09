import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
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
import 'package:lets_play_cities/remote/model/lps_user.dart';
import 'package:lets_play_cities/remote/model/social.dart';
import 'package:lets_play_cities/remote/social/social_network_data.dart';
import 'package:lets_play_cities/remote/social/social_networks_service.dart';
import 'package:lets_play_cities/utils/error_logger.dart';

import 'auth/auth_api_test.dart' show userJson;
import 'fake_server.dart';

class _FakePreferences extends Fake implements GamePreferences {
  @override
  bool get onlineChatEnabled => true;

  @override
  bool signedOut = false;
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

  /// When set, [getUserToken] waits for it
  Completer<void>? tokenGate;

  @override
  Future<String> getUserToken() async {
    await tokenGate?.future;
    return token;
  }

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

  /// The pictures put as the avatar
  final puts = <Uint8List>[];

  /// When set, a download waits for it
  Completer<void>? downloadGate;

  @override
  Future<Uint8List> downloadPicture(String pictureURL) async {
    pictures.add(pictureURL);
    await downloadGate?.future;

    return Uint8List.fromList([1, 2, 3]);
  }

  @override
  Future<LpsUser> putAvatar(Uint8List image) async {
    puts.add(image);
    return LpsUser.fromJson(userJson);
  }
}

class _FakeFactory extends Fake implements ApiRepositoryFactory {
  _FakeFactory(this.serverConfig, this.tokens, this.repository);

  @override
  final AppConfig serverConfig;

  @override
  final TokenStore tokens;

  final _FakeRepository repository;

  @override
  final cache = ApiRepositoryCacheHolder();

  final _drops = StreamController<void>.broadcast();

  @override
  Stream<void> get tokenDrops => _drops.stream;

  @override
  void onTokenDropped() {
    cache.clear();
    _drops.add(null);
  }

  @override
  ApiRepository forUser() => repository;
}

FriendEntry friendEntry(int id) => FriendEntry(
  LpsUser.fromJson({...userJson, 'id': id}),
  FriendStatus.friends,
);

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
  late _FakePreferences preferences;
  late AccountManagerImpl manager;
  late Dio dio;

  setUp(() {
    server = FakeServer();
    tokens = MemoryTokenStore();
    factory = _FakeFactory(config, tokens, _FakeRepository());
    social = _FakeSocialNetworks();
    messaging = _FakeMessaging();
    logger = _RecordingLogger();
    now = DateTime(2026, 11, 8, 12);
    preferences = _FakePreferences();

    dio = createApiDio(
      config,
      tokens,
      onSignedOut: factory.onTokenDropped,
      onError: logger.error,
    )..httpClientAdapter = server;

    manager = AccountManagerImpl(
      preferences: preferences,
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

    test('the uploaded social picture refreshes the account', () async {
      var changes = 0;
      final subscription = manager.accountChanges.listen((_) => changes++);
      addTearDown(subscription.cancel);
      server
        ..on('POST', '/v1/auth/social', 200, _auth('t1', avatarHash: null))
        ..on('GET', '/v1/me', 200, userJson);

      await manager.signInSocial(AuthType.vkontakte);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      // The sign-in and the upload of the picture
      expect(changes, 2);
      await manager.getLastSignedInAccount();
      expect(server.calls, contains('GET /v1/me'));
    });

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

    test(
      'a token dropped by a 401 of another request tells the listeners',
      () async {
        server.on('POST', '/v1/auth/native', 200, _auth('new-token'));
        await manager.signInNative('Мария');
        await pumpEventQueue();
        var changes = 0;
        manager.accountChanges.listen((_) => changes++);
        server.fail('PATCH', '/v1/me', 401, 'unauthorized');

        await expectLater(
          AuthApi(dio).updateMe(name: 'Анна'),
          throwsA(anything),
        );
        await pumpEventQueue();

        expect(changes, 1);
        expect(await manager.getLastSignedInAccount(), isNull);
      },
    );

    test('invalidate makes the next account request ask the server', () async {
      server.on('POST', '/v1/auth/native', 200, _auth('new-token'));
      await manager.signInNative('Мария');
      server.on('GET', '/v1/me', 200, {...userJson, 'avatarHash': 'changed'});

      manager.invalidate();
      final account = await manager.getLastSignedInAccount();

      expect(account?.user.avatarHash, 'changed');
      expect(server.calls, contains('GET /v1/me'));
    });

    test(
      'accountChanges tells about sign-in, invalidate and sign-out',
      () async {
        var changes = 0;
        final subscription = manager.accountChanges.listen((_) => changes++);
        addTearDown(subscription.cancel);
        server
          ..on('POST', '/v1/auth/native', 200, _auth('new-token'))
          ..on('POST', '/v1/auth/logout', 204);

        await manager.signInNative('Мария');
        await Future<void>.delayed(Duration.zero);
        expect(changes, 1);

        manager.invalidate();
        await Future<void>.delayed(Duration.zero);
        expect(changes, 2);

        await manager.signOut();
        await Future<void>.delayed(Duration.zero);
        expect(changes, 3);
      },
    );

    test('sign-in drops the API cache of the previous account', () async {
      factory.cache.cachedFriends = [friendEntry(10)];
      server.on('POST', '/v1/auth/native', 200, _auth('new-token'));

      await manager.signInNative('Мария');

      expect(factory.cache.cachedFriends, isNull);
    });
  });

  group('fcm token', () {
    setUp(() {
      server.on('POST', '/v1/auth/native', 200, _auth('new-token'));
    });

    test('fcm token is patched after sign-in', () async {
      await manager.signInNative('Мария');
      await pumpEventQueue();

      expect(server.bodyOf('PATCH', '/v1/me'), {'fcmToken': 'fcm-1'});
    });

    test('a slow fcm token does not hold the sign-in', () async {
      final gate = messaging.tokenGate = Completer<void>();

      final account = await manager.signInNative('Мария');

      expect(account.userId, 14397);
      expect(server.calls, isNot(contains('PATCH /v1/me')));

      gate.complete();
      await pumpEventQueue();

      expect(server.bodyOf('PATCH', '/v1/me'), {'fcmToken': 'fcm-1'});
    });

    test('an empty fcm token is not sent', () async {
      messaging.token = '';

      await manager.signInNative('Мария');
      await pumpEventQueue();

      expect(server.calls, isNot(contains('PATCH /v1/me')));
    });

    test('a failed patch does not fail the sign-in', () async {
      server.fail('PATCH', '/v1/me', 500, 'internal');

      final account = await manager.signInNative('Мария');
      await pumpEventQueue();

      expect(account.userId, 14397);
      expect(logger.errors, isNotEmpty);
    });

    test(
      'a refreshed token is patched after a sign-in without a sign-out',
      () async {
        await manager.signInNative('Мария');
        await pumpEventQueue();
        await manager.signInNative('Мария');
        await pumpEventQueue();
        server.requests.clear();

        messaging.refreshes.add('fcm-2');
        await pumpEventQueue();

        expect(server.calls, ['PATCH /v1/me']);
        expect(server.bodyOf('PATCH', '/v1/me'), {'fcmToken': 'fcm-2'});
      },
    );

    test('a refreshed token is patched while signed in', () async {
      await manager.signInNative('Мария');
      await pumpEventQueue();

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

  group('a session that ended', () {
    test('a slow fcm token is not sent after the sign-out', () async {
      server.on('POST', '/v1/auth/native', 200, _auth('t1'));
      final gate = messaging.tokenGate = Completer<void>();
      await manager.signInNative('Мария');
      await manager.signOut();
      server.requests.clear();

      gate.complete();
      await pumpEventQueue();

      expect(server.calls, isNot(contains('PATCH /v1/me')));
    });

    test('a slow fcm token is not sent to the next account', () async {
      server.on('POST', '/v1/auth/native', 200, _auth('t1'));
      final gate = messaging.tokenGate = Completer<void>();
      await manager.signInNative('Мария');
      await manager.signOut();
      messaging.tokenGate = null;
      messaging.token = 'fcm-new';
      await manager.signInNative('Мария');
      await pumpEventQueue();
      server.requests.clear();

      // The token of the first session finally arrives
      messaging.token = 'fcm-old';
      gate.complete();
      await pumpEventQueue();

      expect(server.calls, isNot(contains('PATCH /v1/me')));
    });

    test(
      'a refreshed fcm token is sent after the account was refreshed',
      () async {
        server.on('POST', '/v1/auth/native', 200, _auth('t1'));
        await manager.signInNative('Мария');
        await pumpEventQueue();

        // E.g. a new avatar
        manager.invalidate();
        messaging.refreshes.add('fcm-2');
        await pumpEventQueue();

        expect(server.bodyOf('PATCH', '/v1/me'), {'fcmToken': 'fcm-2'});
      },
    );

    test('the picture of a social sign-in does not refresh the next '
        'account', () async {
      server.on('POST', '/v1/auth/social', 200, _auth('t1', avatarHash: null));
      final gate = factory.repository.downloadGate = Completer<void>();
      await manager.signInSocial(AuthType.vkontakte);
      await manager.signOut();
      server.on('POST', '/v1/auth/native', 200, _auth('t2'));
      await manager.signInNative('Мария');
      server.requests.clear();
      var changes = 0;
      final subscription = manager.accountChanges.listen((_) => changes++);
      addTearDown(subscription.cancel);

      gate.complete();
      await pumpEventQueue();

      expect(factory.repository.puts, isEmpty);
      expect(changes, 0);
      await manager.getLastSignedInAccount();
      expect(server.calls, isNot(contains('GET /v1/me')));
    });
  });

  group('after sign-out', () {
    setUp(() async {
      server.on('POST', '/v1/auth/native', 200, _auth('session'));
      await manager.signInNative('Мария');
      await pumpEventQueue();
      await manager.signOut();
      server.requests.clear();
    });

    test('silent native sends no request', () async {
      expect(preferences.signedOut, isTrue);
      expect(await manager.trySilentNative(), isNull);
      expect(server.calls, isEmpty);
    });

    test('a sign-in clears the flag and silent native works again', () async {
      await manager.signInNative('Мария');

      expect(preferences.signedOut, isFalse);

      await tokens.clear();
      server.requests.clear();
      expect(await manager.trySilentNative(), isNotNull);
      expect(server.calls, contains('POST /v1/auth/native'));
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
      await pumpEventQueue();
      factory.cache.cachedFriends = [friendEntry(10)];
      server.requests.clear();
    });

    test(
      'signOut calls logout then clears token even if logout fails',
      () async {
        server.fail('POST', '/v1/auth/logout', 500, 'internal');

        await manager.signOut();

        expect(server.calls, ['PATCH /v1/me', 'POST /v1/auth/logout']);
        expect(server.requests.last.headers['Authorization'], 'Bearer session');
        expect(await tokens.read(), isNull);
        expect(factory.cache.cachedFriends, isNull);
        expect(await manager.getLastSignedInAccount(), isNull);
      },
    );

    test('signOut stops the pushes to the device before logout', () async {
      await manager.signOut();

      expect(server.calls, ['PATCH /v1/me', 'POST /v1/auth/logout']);
      expect(server.bodyOf('PATCH', '/v1/me'), {'fcmToken': ''});
      expect(server.requests.first.headers['Authorization'], 'Bearer session');
    });

    test('signOut still logs out when the push token is not cleared', () async {
      server.fail('PATCH', '/v1/me', 500, 'internal');

      await manager.signOut();

      expect(server.calls, ['PATCH /v1/me', 'POST /v1/auth/logout']);
      expect(await tokens.read(), isNull);
    });

    test('signOut without the network still signs out', () async {
      server.offline = true;

      await manager.signOut();

      expect(await tokens.read(), isNull);
    });

    test('signOut closes the game connection', () async {
      var closes = 0;
      final manager = AccountManagerImpl(
        preferences: preferences,
        apiRepositories: factory,
        auth: AuthApi(
          createApiDio(config, tokens, onError: logger.error)
            ..httpClientAdapter = server,
        ),
        socialNetworks: social,
        messaging: messaging,
        logger: logger,
        onSignedOut: () async => closes++,
      );

      await manager.signOut();

      expect(closes, 1);
      expect(await tokens.read(), isNull);
    });
  });
}
