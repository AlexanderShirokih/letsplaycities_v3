import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/remote/api_repository_factory.dart';
import 'package:lets_play_cities/remote/auth.dart';

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

/// Credentials that the test can change between requests.
class _ChangingCredentials implements CredentialsProvider {
  Credential current = const Credential(userId: 1, accessToken: 'first');

  @override
  Credential getCredentials() => current;
}

String _authorization(Credential credential) =>
    credential.asAuthorizationHeader()['authorization']!;

void main() {
  final mainServer = AppConfig.forHost('main.test');
  final lanServer = AppConfig.forHost(
    '192.168.1.5',
    isSecure: false,
    port: 8988,
  );
  const owner = Credential(userId: 1, accessToken: 'token');
  final aliceWithPicture = {
    'userId': 2,
    'login': 'Alice',
    'accepted': true,
    'sender': false,
    'pictureHash': 'abc',
  };

  late _FakeServer server;
  late List<AppConfig> dioConfigs;
  late ApiRepositoryCacheHolder cache;
  late ApiRepositoryFactory factory;

  setUp(() {
    server = _FakeServer();
    dioConfigs = [];
    cache = ApiRepositoryCacheHolder();
    factory = ApiRepositoryFactory(mainServer, cache, (config) {
      dioConfigs.add(config);
      return Dio(BaseOptions(baseUrl: config.remotePublicApiURL))
        ..httpClientAdapter = server;
    });
  });

  group('the main server factory', () {
    test('sends repository requests to the main server as the user', () async {
      server.respond = (_) => [aliceWithPicture];

      final friends = await factory.forCredential(owner).getFriendsList(true);

      final request = server.requests.single;
      expect(request.uri.toString(), 'https://main.test:8443/friend/');
      expect(request.headers['authorization'], _authorization(owner));
      expect(friends.single.pictureUrl, startsWith('https://main.test:8443/'));
      expect(factory.serverConfig, mainServer);
    });

    test('clientFor signs the requests with the given credential', () async {
      const other = Credential(userId: 7, accessToken: 'other');

      await factory.clientFor(other).getBanList();

      final request = server.requests.single;
      expect(request.uri.host, 'main.test');
      expect(request.headers['authorization'], _authorization(other));
    });

    test('clientWith reads the credentials on every request', () async {
      final credentials = _ChangingCredentials();
      final client = factory.clientWith(credentials);

      await client.getBanList();
      credentials.current = const Credential(userId: 1, accessToken: 'second');
      await client.getBanList();

      expect(server.requests.map((r) => r.headers['authorization']), [
        _authorization(const Credential(userId: 1, accessToken: 'first')),
        _authorization(const Credential(userId: 1, accessToken: 'second')),
      ]);
    });

    test(
      'downloads a picture from its URL and uploads it as the user',
      () async {
        final png = img.encodePng(img.Image(width: 2, height: 2));
        server.respond = (request) =>
            request.uri.host == 'pictures.example' ? png : <String, Object>{};

        await factory
            .forCredential(owner)
            .updatePictureFromURL('https://pictures.example/avatar.png');

        final [download, upload] = server.requests;
        expect(download.uri.toString(), 'https://pictures.example/avatar.png');
        expect(
          upload.uri.toString(),
          'https://main.test:8443/user/picture/upload',
        );
        expect(upload.headers['authorization'], _authorization(owner));
        // One Dio serves both the API requests and the picture download.
        expect(dioConfigs, [mainServer]);
      },
    );
  });

  group('forServer', () {
    test(
      'sends the requests to that server with the same credential',
      () async {
        await factory
            .forServer(lanServer)
            .forCredential(owner)
            .getBanlist(true);

        final request = server.requests.single;
        expect(request.uri.toString(), 'http://192.168.1.5:8988/blacklist/');
        expect(request.headers['authorization'], _authorization(owner));
        expect(dioConfigs, [lanServer]);
      },
    );

    test('keeps the picture URLs on the main server', () async {
      server.respond = (_) => [aliceWithPicture];

      final friends = await factory
          .forServer(lanServer)
          .clientFor(owner)
          .getFriendsList();

      expect(server.requests.single.uri.host, '192.168.1.5');
      expect(
        friends.single.pictureUrl,
        'https://main.test:8443/user/2/picture?hash=abc',
      );
    });

    test('shares the cache with the factory it was made from', () async {
      server.respond = (_) => [aliceWithPicture];
      final lanFactory = factory.forServer(lanServer);

      await lanFactory.forCredential(owner).getFriendsList(true);
      final cached = await factory.forCredential(owner).getFriendsList(false);

      expect(lanFactory.cache, same(cache));
      expect(cache.cachedFriendsList, cached);
      expect(server.requests, hasLength(1));
    });

    test('leaves the original factory on its server', () async {
      factory.forServer(lanServer);

      await factory.clientFor(owner).getBanList();

      expect(factory.serverConfig, mainServer);
      expect(server.requests.single.uri.host, 'main.test');
    });
  });
}
