import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/base/remote/bloc/local_multiplayer_bloc.dart';
import 'package:lets_play_cities/remote/api_repository_factory.dart';
import 'package:lets_play_cities/remote/auth.dart';
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
          'userId': 2,
          'login': 'Alice',
          'accepted': true,
          'sender': false,
          'pictureHash': 'abc',
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
  final lanConfig = AppConfig.forHost(
    '192.168.1.5',
    isSecure: false,
    port: 8988,
  );
  const lanCredential = Credential(userId: 9, accessToken: 'lan');
  final lanAccountManager = _FakeAccountManager();

  late GetIt getIt;
  late _FakeServer server;
  late ApiRepositoryCacheHolder cache;
  late ApiRepositoryFactory mainApiRepositories;

  setUp(() {
    getIt = GetIt.asNewInstance();
    server = _FakeServer();
    cache = ApiRepositoryCacheHolder();
    mainApiRepositories = ApiRepositoryFactory(
      mainConfig,
      cache,
      (config) =>
          Dio(BaseOptions(baseUrl: config.remotePublicApiURL))
            ..httpClientAdapter = server,
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

    final friends = await apiRepositories
        .forCredential(lanCredential)
        .getFriendsList(true);

    final request = server.requests.single;
    expect(request.uri.toString(), 'http://192.168.1.5:8988/friend/');
    expect(
      request.headers['authorization'],
      lanCredential.asAuthorizationHeader()['authorization'],
    );
    expect(
      friends.single.pictureUrl,
      'https://main.test:8443/user/2/picture?hash=abc',
    );
    expect(apiRepositories.cache, same(cache));
    expect(cache.cachedFriendsList, friends);
  });

  test('popping the scope brings the main server factory back', () async {
    pushScope();
    await getIt.popScope();

    expect(getIt<AppConfig>(), mainConfig);
    expect(getIt<ApiRepositoryFactory>(), same(mainApiRepositories));
  });
}
