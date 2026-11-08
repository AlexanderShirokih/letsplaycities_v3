import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/remote/model/lps_user.dart';
import 'package:lets_play_cities/remote/model/social.dart';
import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/remote/api_repository_factory.dart';
import 'package:lets_play_cities/remote/auth/token_store.dart';
import 'package:lets_play_cities/remote/client/api_dio.dart';
import 'package:lets_play_cities/remote/client/api_exception.dart';

import '../auth/auth_api_test.dart' show userJson;
import '../fake_server.dart';

/// A store whose token cannot be deleted
class _StuckTokenStore extends MemoryTokenStore {
  _StuckTokenStore(super.token);

  @override
  Future<void> clear() async => throw StateError('Keychain is locked');
}

void main() {
  final config = AppConfig.forHost('lps.test');

  late FakeServer server;
  late List<Object> errors;
  late int signOuts;

  setUp(() {
    server = FakeServer()..fail('GET', '/v1/me', 401, 'unauthorized');
    errors = [];
    signOuts = 0;
  });

  Dio dioFor(TokenStore tokens) => createApiDio(
    config,
    tokens,
    onSignedOut: () => signOuts++,
    onError: (e, s) => errors.add(e),
  )..httpClientAdapter = server;

  Future<void> expectUnauthorized(Future<Object?> request) => expectLater(
    request,
    throwsA(
      isA<DioException>().having(
        (e) => e.error,
        'error',
        isA<UnauthorizedException>(),
      ),
    ),
  );

  test('401 drops the token that the request sent', () async {
    final tokens = MemoryTokenStore('old');

    await expectUnauthorized(dioFor(tokens).get('/me'));

    expect(await tokens.read(), isNull);
    expect(signOuts, 1);
  });

  test('a late 401 keeps the token of a newer sign-in', () async {
    final tokens = MemoryTokenStore('old');
    server.beforeReply = (_) => tokens.write('new');

    await expectUnauthorized(dioFor(tokens).get('/me'));

    expect(await tokens.read(), 'new');
    expect(signOuts, 0);
  });

  test('a token that cannot be deleted is logged, not thrown', () async {
    final tokens = _StuckTokenStore('old');

    await expectUnauthorized(dioFor(tokens).get('/me'));

    expect(errors, [isA<StateError>()]);
  });

  test('the main factory drops the token and the API cache on 401', () async {
    final tokens = MemoryTokenStore('old');
    final factory = ApiRepositoryFactory.main(
      config,
      tokens,
      onError: (e, s) => errors.add(e),
    );
    factory.cache.cachedFriends = [
      FriendEntry(LpsUser.fromJson(userJson), FriendStatus.friends),
    ];

    await expectUnauthorized(
      (factory.dio()..httpClientAdapter = server).get('/me'),
    );

    expect(await tokens.read(), isNull);
    expect(factory.cache.cachedFriends, isNull);
    expect(errors, isEmpty);
  });

  group('dropSentToken', () {
    test('drops the token that was sent', () async {
      final tokens = MemoryTokenStore('t');

      await dropSentToken(
        tokens,
        't',
        onSignedOut: () => signOuts++,
        onError: (e, s) => errors.add(e),
      );

      expect(await tokens.read(), isNull);
      expect(signOuts, 1);
    });

    test('keeps the token of a newer sign-in', () async {
      final tokens = MemoryTokenStore('new');

      await dropSentToken(
        tokens,
        'old',
        onSignedOut: () => signOuts++,
        onError: (e, s) => errors.add(e),
      );

      expect(await tokens.read(), 'new');
      expect(signOuts, 0);
    });
  });
}
