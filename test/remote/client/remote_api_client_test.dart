import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/auth/token_store.dart';
import 'package:lets_play_cities/remote/client/api_interceptor.dart';
import 'package:lets_play_cities/remote/exceptions.dart';

/// Answers each path in [responses] with its JSON body, anything else with
/// [missingStatus], and records the requested paths in [requests].
class _FakeServer implements HttpClientAdapter {
  final Map<String, Object> responses;
  final int missingStatus;
  final requests = <String>[];

  _FakeServer(this.responses, {this.missingStatus = 404});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options.path);
    final body = responses[options.path];
    if (body == null) {
      return ResponseBody.fromString('', missingStatus);
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
  const ownerId = 1;
  // The picture host differs from the Dio host, so the tests show which one
  // the picture URLs come from.
  final config = AppConfig.forHost('pictures.test');
  const picturePrefix = 'https://pictures.test:443/user';

  late _FakeServer server;

  RemoteLpsApiClient client(Map<String, Object> responses) {
    server = _FakeServer(responses);
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = server;
    return RemoteLpsApiClient(config, dio, MemoryTokenStore('token'), ownerId);
  }

  test('a 401 response throws AccessDeniedException', () {
    server = _FakeServer(const {}, missingStatus: 401);
    final api = RemoteLpsApiClient(
      config,
      Dio(BaseOptions(baseUrl: 'https://api.test'))..httpClientAdapter = server,
      MemoryTokenStore('token'),
      ownerId,
    );

    expect(api.getFriendsList(), throwsA(isA<AccessDeniedException>()));
  });

  test('getFriendsList builds picture URLs from the client config', () async {
    final friends = await client({
      '/friend/': [
        {
          'userId': 2,
          'login': 'Alice',
          'accepted': true,
          'sender': false,
          'pictureHash': 'abc',
        },
        {'userId': 3, 'login': 'Bob', 'accepted': false, 'sender': true},
      ],
    }).getFriendsList();

    expect(server.requests, ['/friend/']);
    expect(friends.map((f) => f.login), ['Alice', 'Bob']);
    expect(friends[0].pictureUrl, '$picturePrefix/2/picture?hash=abc');
    expect(friends[1].pictureUrl, isNull);
  });

  test('getBanList builds picture URLs from the client config', () async {
    final banned = await client({
      '/blacklist/': [
        {'userId': 4, 'login': 'Eve', 'pictureHash': 'def'},
      ],
    }).getBanList();

    expect(server.requests, ['/blacklist/']);
    expect(banned.single.login, 'Eve');
    expect(banned.single.pictureUrl, '$picturePrefix/4/picture?hash=def');
  });

  group('getHistoryList', () {
    final record = {
      'userId': 5,
      'login': 'Carol',
      'isFriend': 'true',
      'duration': 60,
      'wordsCount': 8,
      'startTime': 1700000000000,
      'pictureHash': 'ghi',
    };

    test('builds picture URLs from the client config', () async {
      final history = await client({
        '/history/': [record],
      }).getHistoryList();

      expect(history.single.login, 'Carol');
      expect(history.single.isFriend, isTrue);
      expect(history.single.pictureUrl, '$picturePrefix/5/picture?hash=ghi');
    });

    test(
      'asks for the own history without a target or for the owner',
      () async {
        final api = client({
          '/history/': [record],
        });

        await api.getHistoryList();
        await api.getHistoryList(ownerId);

        expect(server.requests, ['/history/', '/history/']);
      },
    );

    test('asks for the history of another user by id', () async {
      final api = client({
        '/history/5': [record],
      });

      await api.getHistoryList(5);

      expect(server.requests, ['/history/5']);
    });
  });

  group('with the API interceptor', () {
    RemoteLpsApiClient apiWith(int missingStatus, [String? token = 'token']) {
      server = _FakeServer(const {}, missingStatus: missingStatus);
      final tokens = MemoryTokenStore(token);
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test/v1'))
        ..httpClientAdapter = server
        ..interceptors.add(ApiInterceptor(tokens, onUnauthorized: () {}));
      return RemoteLpsApiClient(config, dio, tokens, ownerId);
    }

    test('204 No Content is a success', () async {
      await apiWith(204).deleteFriend(5);

      expect(server.requests, ['/friend/5']);
    });

    test('401 throws AccessDeniedException', () {
      expect(
        apiWith(401).getFriendsList(),
        throwsA(isA<AccessDeniedException>()),
      );
    });

    test('an error answer throws FetchingException', () {
      expect(apiWith(403).deleteFriend(5), throwsA(isA<FetchingException>()));
    });

    test('a request without a token fails before it is sent', () async {
      final api = apiWith(200, null);

      await expectLater(
        api.getFriendsList(),
        throwsA(isA<NotAuthorizedException>()),
      );
      expect(server.requests, isEmpty);
    });
  });
}
