import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/base/remote/bloc/local_multiplayer_bloc.dart';
import 'package:lets_play_cities/remote/api_repository_factory.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/auth/token_store.dart';
import 'package:lets_play_cities/remote/client/api_interceptor.dart';
import 'package:lets_play_cities/remote/server/user_lookup_repository.dart';
import 'package:lets_play_cities/screens/multiplayer/local_multiplayer_screen.dart';

/// Answers every request with one friend that has a picture and records the
/// requests.
class _FakeServer implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode([
        {
          'user': {
            'id': 2,
            'name': 'Alice',
            'avatarHash': 'abc',
            'provider': 'native',
            'lastSeenAt': 1700000000000,
          },
          'status': 'friends',
        },
      ]),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _FakeAccountManager extends Fake implements AccountManager {}

void main() {
  final mainConfig = AppConfig.forHost('main.test');
  final lanConfig = AppConfig.lan('192.168.1.5');
  final lanAccountManager = _FakeAccountManager();

  late GetIt getIt;
  late _FakeServer server;
  late ApiRepositoryCacheHolder cache;
  late ApiRepositoryFactory mainApiRepositories;
  late MemoryTokenStore mainTokens;

  setUp(() {
    getIt = GetIt.asNewInstance();
    server = _FakeServer();
    mainTokens = MemoryTokenStore('main');
    cache = ApiRepositoryCacheHolder();
    mainApiRepositories = ApiRepositoryFactory(
      mainConfig,
      cache,
      mainTokens,
      (config, tokens) => Dio(BaseOptions(baseUrl: config.restBaseUrl))
        ..httpClientAdapter = server
        ..interceptors.add(
          ApiInterceptor(tokens, onUnauthorized: (_) async {}),
        ),
    );
    getIt
      ..registerSingleton<AppConfig>(mainConfig)
      ..registerSingleton<AccountManager>(_FakeAccountManager())
      ..registerSingleton<ApiRepositoryFactory>(mainApiRepositories)
      ..registerSingleton<UserLookupRepository>(UserLookupRepositoryImpl());
  });

  void pushScope() => pushLanGameScope(
    getIt,
    LocalMultiplayerStartGame(lanConfig, lanAccountManager),
  );

  test('the scope registers the LAN config and account manager', () {
    pushScope();

    expect(getIt<AppConfig>(), lanConfig);
    expect(getIt<AccountManager>(), same(lanAccountManager));
  });

  test('inside the scope the API factory sends the requests to the LAN '
      'server and keeps the main picture URLs and cache', () async {
    pushScope();
    final apiRepositories = getIt<ApiRepositoryFactory>();

    await apiRepositories.tokens.write('lan');

    final repository = apiRepositories.forUser();
    final friends = await repository.friends(true);

    final request = server.requests.single;
    expect(request.uri.toString(), 'http://192.168.1.5:8988/friends');
    // The LAN game has its own token, the main one stays out of it.
    expect(request.headers['Authorization'], 'Bearer lan');
    expect(await mainTokens.read(), 'main');
    expect(
      repository.avatarUrl(friends.single.user),
      'https://main.test:443/v1/avatars/2?v=abc',
    );
    expect(apiRepositories.cache, same(cache));
    expect(cache.cachedFriends, friends);
  });

  test('popping the scope brings the main server factory back', () async {
    pushScope();
    await getIt.popScope();

    expect(getIt<AppConfig>(), mainConfig);
    expect(getIt<ApiRepositoryFactory>(), same(mainApiRepositories));
  });
}
