import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/remote/api_repository_factory.dart';
import 'package:lets_play_cities/remote/api_repository.dart';
import 'package:lets_play_cities/remote/auth/token_store.dart';
import 'package:lets_play_cities/remote/client/api_interceptor.dart';

/// Answers every request with the body [respond] gives for it and records
/// the requests.
class _FakeServer implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  /// Body of the reply to a request, encoded as JSON unless it is bytes.
  Object Function(RequestOptions request) respond = (_) => <Object>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final body = respond(options);
    if (body is List<int>) {
      return ResponseBody.fromBytes(body, 200);
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  final mainServer = AppConfig.forHost('main.test');
  final alice = {
    'id': 2,
    'name': 'Alice',
    'avatarHash': 'abc',
    'provider': 'native',
    'lastSeenAt': 1700000000000,
  };
  final aliceWithPicture = {'user': alice, 'status': 'friends'};

  late _FakeServer server;
  late List<AppConfig> dioConfigs;
  late MemoryTokenStore tokens;
  late ApiRepositoryCacheHolder cache;
  late ApiRepositoryFactory factory;

  setUp(() {
    server = _FakeServer();
    dioConfigs = [];
    tokens = MemoryTokenStore('token');
    cache = ApiRepositoryCacheHolder();
    factory = ApiRepositoryFactory(mainServer, cache, tokens, (config, tokens) {
      dioConfigs.add(config);
      return Dio(BaseOptions(baseUrl: config.restBaseUrl))
        ..httpClientAdapter = server
        ..interceptors.add(
          ApiInterceptor(tokens, onUnauthorized: (_) async {}),
        );
    });
  });

  group('the main server factory', () {
    test('sends repository requests to the main server as the user', () async {
      server.respond = (_) => [aliceWithPicture];

      final repository = factory.forUser();
      final friends = await repository.friends(true);

      final request = server.requests.single;
      expect(request.uri.toString(), 'https://main.test/v1/friends');
      expect(request.headers['Authorization'], 'Bearer token');
      expect(
        repository.avatarUrl(friends.single.user),
        startsWith('https://main.test:443/'),
      );
      expect(factory.serverConfig, mainServer);
    });

    test('clientFor signs the requests with the current token', () async {
      final client = factory.clientFor();

      await client.getCityRequests();
      await tokens.write('second');
      await client.getCityRequests();

      expect(server.requests.map((r) => r.headers['Authorization']), [
        'Bearer token',
        'Bearer second',
      ]);
    });

    test(
      'downloads a picture from its URL and uploads it as the user',
      () async {
        final png = img.encodePng(img.Image(width: 2, height: 2));
        server.respond = (request) =>
            request.uri.host == 'pictures.example' ? png : alice;

        await factory.forUser().putAvatarFromUrl(
          'https://pictures.example/avatar.png',
        );

        final [download, upload] = server.requests;
        expect(download.uri.toString(), 'https://pictures.example/avatar.png');
        expect(upload.uri.toString(), 'https://main.test/v1/me/avatar');
        expect(upload.method, 'PUT');
        expect(upload.headers['Authorization'], 'Bearer token');
        expect(upload.headers['content-type'], 'image/png');
        // The token stays with the API: the picture host never sees it.
        expect(download.headers, isNot(contains('Authorization')));
        // One Dio serves both the API requests and the picture download.
        expect(dioConfigs, [mainServer]);
      },
    );
  });
}
