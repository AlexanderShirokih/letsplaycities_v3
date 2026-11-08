import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/remote/auth/token_store.dart';
import 'package:lets_play_cities/remote/client/api_exception.dart';
import 'package:lets_play_cities/remote/client/api_interceptor.dart';

/// Answers every request with [status] and [body], and records the requests.
class _FakeServer implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  int status = 200;
  String body = '{}';
  String contentType = Headers.jsonContentType;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: [contentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _FakeServer server;
  late MemoryTokenStore tokens;
  late List<String?> unauthorized;
  late Dio dio;

  setUp(() {
    server = _FakeServer();
    tokens = MemoryTokenStore('secret');
    unauthorized = [];
    dio = Dio(BaseOptions(baseUrl: 'https://lps.test:443/v1'))
      ..httpClientAdapter = server
      ..interceptors.add(
        ApiInterceptor(
          tokens,
          onUnauthorized: (sentToken) async => unauthorized.add(sentToken),
        ),
      );
  });

  /// The [ApiException] that the request fails with.
  Future<ApiException> failure(Future<Object?> request) async {
    try {
      await request;
    } on DioException catch (e) {
      return e.error! as ApiException;
    }
    fail('The request must fail');
  }

  test('interceptor adds bearer', () async {
    await dio.get('/friends');

    expect(server.requests.single.headers['Authorization'], 'Bearer secret');
  });

  test('no token means no Authorization header', () async {
    await tokens.clear();

    await dio.get('/friends');

    expect(server.requests.single.headers, isNot(contains('Authorization')));
  });

  test('204 is success', () async {
    server
      ..status = 204
      ..body = '';

    final response = await dio.delete('/friends/5');

    expect(response.statusCode, 204);
  });

  test('201 is success', () async {
    server.status = 201;

    final response = await dio.post('/city-edits', data: {'a': 1});

    expect(response.statusCode, 201);
  });

  test('the version is not repeated in a path that has it', () async {
    await dio.get('/v1/friends');
    await dio.get('/friends');

    expect(server.requests.map((r) => r.uri.toString()), [
      'https://lps.test/v1/friends',
      'https://lps.test/v1/friends',
    ]);
  });

  test('error body becomes ApiException with code and message', () async {
    server
      ..status = 400
      ..body = jsonEncode({
        'error': {'code': 'bad_name', 'message': 'Name is taken'},
      });

    final e = await failure(dio.post('/me'));

    expect(e, isNot(isA<BannedException>()));
    expect(e.status, 400);
    expect(e.code, 'bad_name');
    expect(e.message, 'Name is taken');
  });

  test('403 banned becomes BannedException', () async {
    server
      ..status = 403
      ..body = jsonEncode({
        'error': {'code': 'banned', 'message': 'Rude'},
      });

    final e = await failure(dio.get('/me'));

    expect(e, isA<BannedException>());
    expect(e.status, 403);
    expect(e.message, 'Rude');
    expect(unauthorized, isEmpty);
  });

  test('401 calls onUnauthorized with the token it sent', () async {
    server
      ..status = 401
      ..body = jsonEncode({
        'error': {'code': 'unauthorized', 'message': 'Expired'},
      });

    final e = await failure(dio.get('/me'));

    expect(e, isA<UnauthorizedException>());
    expect(e.status, 401);
    expect(unauthorized, ['secret']);
  });

  test('a rejected provider token is not a lost session', () async {
    server
      ..status = 401
      ..body = jsonEncode({
        'error': {'code': 'invalid_provider_token', 'message': 'No'},
      });

    final e = await failure(dio.post('/auth/social'));

    expect(e, isNot(isA<UnauthorizedException>()));
    expect(e.code, 'invalid_provider_token');
    expect(unauthorized, isEmpty);
  });

  test('a 401 without an error body is a lost session', () async {
    server
      ..status = 401
      ..contentType = Headers.textPlainContentType
      ..body = 'Unauthorized';

    final e = await failure(dio.get('/me'));

    expect(e, isA<UnauthorizedException>());
    expect(unauthorized, ['secret']);
  });

  test(
    'a relative path with a URL in its query still gets the token',
    () async {
      await dio.get('/history?ref=https://other.test/page');

      expect(server.requests.single.headers['Authorization'], 'Bearer secret');
    },
  );

  test("non-json error body keeps status with code 'internal'", () async {
    server
      ..status = 502
      ..contentType = Headers.textPlainContentType
      ..body = '<html>Bad gateway</html>';

    final e = await failure(dio.get('/me'));

    expect(e.status, 502);
    expect(e.code, 'internal');
    expect(e.message, isNull);
  });

  test(
    'a request to another host gets no token and no error mapping',
    () async {
      server
        ..status = 401
        ..body = 'no';

      try {
        await dio.get('https://pictures.example/avatar.png');
        fail('The request must fail');
      } on DioException catch (e) {
        expect(e.error, isNot(isA<ApiException>()));
      }

      expect(server.requests.single.headers, isNot(contains('Authorization')));
      expect(unauthorized, isEmpty);
    },
  );
}
