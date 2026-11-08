import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/cities_list/city_request.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/auth/token_store.dart';
import 'package:lets_play_cities/remote/client/api_interceptor.dart';
import 'package:lets_play_cities/remote/exceptions.dart';

import '../fake_server.dart';

void main() {
  late FakeServer server;

  RemoteLpsApiClient apiWith(MemoryTokenStore tokens) {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test/v1'))
      ..httpClientAdapter = server
      ..interceptors.add(ApiInterceptor(tokens, onUnauthorized: (_) async {}));

    return RemoteLpsApiClient(dio, tokens);
  }

  setUp(() => server = FakeServer());

  test('the city requests are read from /cities/edit', () async {
    server.on('GET', '/v1/cities/edit', 200, <Object>[]);

    final requests = await apiWith(MemoryTokenStore('token')).getCityRequests();

    expect(requests, isEmpty);
    expect(server.requests.single.headers['Authorization'], 'Bearer token');
  });

  test('a 401 response throws AccessDeniedException', () {
    server.fail('GET', '/v1/cities/edit', 401, 'unauthorized');

    expect(
      apiWith(MemoryTokenStore('token')).getCityRequests(),
      throwsA(isA<AccessDeniedException>()),
    );
  });

  test('an error answer throws FetchingException', () {
    server.fail('POST', '/v1/cities/edit', 403, 'banned');

    expect(
      apiWith(MemoryTokenStore('token')).sendCityRequest(
        SendCityRequest(newCountryCode: 1, newName: 'City', reason: 'r'),
      ),
      throwsA(isA<FetchingException>()),
    );
  });

  test('a request without a token fails before it is sent', () async {
    final api = apiWith(MemoryTokenStore());

    await expectLater(
      api.getCityRequests(),
      throwsA(isA<NotAuthorizedException>()),
    );
    expect(server.requests, isEmpty);
  });
}
