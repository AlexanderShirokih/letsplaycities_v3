import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/base/remote/bloc/local_multiplayer_bloc.dart';
import 'package:lets_play_cities/remote/api_repository_factory.dart';
import 'package:lets_play_cities/remote/auth/token_store.dart';
import 'package:lets_play_cities/remote/client/api_dio.dart';
import 'package:lets_play_cities/remote/game_connection.dart';
import 'package:lets_play_cities/screens/multiplayer/lan_scope.dart';
import 'package:lets_play_cities/screens/multiplayer/local_multiplayer_screen.dart';
import 'package:lets_play_cities/utils/error_logger.dart';

/// Records the requests and answers each with an empty JSON object
class _FakeAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);

    return ResponseBody.fromString(
      '{}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// The store of the main token; counts the reads
class _MainTokens implements TokenStore {
  var reads = 0;

  @override
  Future<String?> read() async {
    reads++;

    return 'main';
  }

  @override
  Future<void> write(String token) async {}

  @override
  Future<void> clear() async {}
}

class _FakePreferences extends Fake implements GamePreferences {
  @override
  String lastNativeLogin = '';
}

void main() {
  final mainConfig = AppConfig.forHost('main.test');
  final lanConfig = AppConfig.lan('192.168.1.5');

  late GetIt getIt;
  late _MainTokens mainTokens;
  late _FakePreferences preferences;
  late ApiRepositoryFactory mainApiRepositories;

  setUp(() {
    getIt = GetIt.asNewInstance();
    mainTokens = _MainTokens();
    preferences = _FakePreferences();
    mainApiRepositories = ApiRepositoryFactory.main(
      mainConfig,
      mainTokens,
      onError: (_, _) {},
    );
    getIt
      ..registerSingleton<AppConfig>(mainConfig)
      ..registerSingleton<TokenStore>(mainTokens)
      ..registerSingleton<ApiRepositoryFactory>(mainApiRepositories)
      ..registerFactory<Dio>(
        () => createApiDio(
          getIt.get<AppConfig>(),
          getIt.get<TokenStore>(),
          onError: (_, _) {},
        ),
      )
      ..registerSingleton<ErrorLogger>(SimpleErrorLogger())
      ..registerSingleton<GamePreferences>(preferences);
  });

  void pushScope([AppConfig? config]) =>
      pushLanGameScope(getIt, LocalMultiplayerStartGame(config ?? lanConfig));

  test('the scope registers the LAN config under its name', () {
    pushScope();

    expect(getIt<AppConfig>(), lanConfig);
    expect(getIt.currentScopeName, lanGameScopeName);
  });

  test('the scope has its own game connection', () async {
    final main = GameConnection.forApp(
      url: 'wss://main.test/v1/game',
      headers: () async => {'Authorization': 'Bearer main'},
      playerName: () => '',
    );
    getIt.registerSingleton<GameConnection>(main);

    pushScope();

    expect(getIt<GameConnection>(), isNot(same(main)));
    await getIt.popScope();
    expect(getIt<GameConnection>(), same(main));
  });

  group('the LAN game connection', () {
    late HttpServer host;
    late List<HttpHeaders> upgrades;
    late List<Map<String, dynamic>> hellos;

    setUp(() async {
      upgrades = [];
      hellos = [];
      host = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      host.listen((request) async {
        upgrades.add(request.headers);
        final socket = await WebSocketTransformer.upgrade(request);
        socket.listen((frame) {
          final hello = jsonDecode(frame as String) as Map<String, dynamic>;
          hellos.add(hello);
          socket.add(
            jsonEncode({
              'type': 'welcome',
              'user': {
                'id': 1,
                'name': hello['name'],
                'avatarHash': null,
                'provider': 'lan',
                'lastSeenAt': 0,
              },
            }),
          );
        });
      });
    });

    tearDown(() async {
      await getIt.get<GameConnection>().close();
      await host.close(force: true);
    });

    Future<void> connect() async {
      pushScope(AppConfig.lan('127.0.0.1', port: host.port));
      await getIt.get<GameConnection>().ensureConnected();
    }

    test('goes to /v1/game of the host without the main token', () async {
      preferences.lastNativeLogin = 'Вася';

      await connect();

      expect(upgrades.single.value(HttpHeaders.authorizationHeader), isNull);
      expect(hellos.single['protocol'], 1);
      expect(hellos.single['name'], 'Вася');
      expect(mainTokens.reads, 0);
    });

    test('says «Игрок» when no name was ever entered', () async {
      preferences.lastNativeLogin = '  ';

      await connect();

      expect(hellos.single['name'], 'Игрок');
    });
  });

  test('inside the scope the REST requests go to the main server and never '
      'carry the main token', () async {
    pushScope();

    // The game screen builds its dictionary updater from this Dio
    final dio = getIt.get<Dio>();
    final adapter = _FakeAdapter();
    dio.httpClientAdapter = adapter;
    await dio.get<Object?>('/dictionary');

    final request = adapter.requests.single;
    expect(request.uri.toString(), 'https://main.test/v1/dictionary');
    expect(request.headers[HttpHeaders.authorizationHeader], isNull);
    expect(mainTokens.reads, 0);

    // No API factory of the LAN host: the LAN host has no REST
    expect(getIt<ApiRepositoryFactory>(), same(mainApiRepositories));
  });

  test('popping the scope brings the main server back', () async {
    pushScope();
    await getIt.popScope();

    expect(getIt<AppConfig>(), mainConfig);
    expect(getIt.currentScopeName, isNot(lanGameScopeName));
  });
}
