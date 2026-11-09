import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/cities_list/city_request.dart';
import 'package:lets_play_cities/remote/auth/token_store.dart';
import 'package:lets_play_cities/remote/city_requests_repository.dart';
import 'package:lets_play_cities/remote/client/api_exception.dart';
import 'package:lets_play_cities/remote/client/api_interceptor.dart';
import 'package:lets_play_cities/remote/client/remote_api_client.dart';
import 'package:lets_play_cities/remote/exceptions.dart';

import 'fake_server.dart';

const _created = {
  'id': 7,
  'oldCountryCode': null,
  'newCountryCode': 91,
  'oldName': null,
  'newName': 'Новоград',
  'reason': 'есть в Википедии',
  'verdict': null,
  'status': 'NEW',
};

void main() {
  late FakeServer server;

  CityRequestsRepository repositoryWith(MemoryTokenStore tokens) {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test/v1'))
      ..httpClientAdapter = server
      ..interceptors.add(ApiInterceptor(tokens, onUnauthorized: (_) async {}));

    return CityRequestsRepository(RemoteLpsApiClient(dio, tokens));
  }

  setUp(() => server = FakeServer());

  test('city edits are read from /v1/city-edits', () async {
    server.on('GET', '/v1/city-edits', 200, [_created]);

    final requests = await repositoryWith(MemoryTokenStore('token'))
        .getRequests();

    expect(requests.single.newName, 'Новоград');
    expect(requests.single.status, CityRequestStatus.newRequest);
    expect(server.requests.single.headers['Authorization'], 'Bearer token');
  });

  test('city edits post returns created request', () async {
    server.on('POST', '/v1/city-edits', 201, _created);

    final created = await repositoryWith(MemoryTokenStore('token'))
        .sendAddCityRequest(
          newCountryCode: 91,
          newCityName: 'Новоград',
          reason: 'есть в Википедии',
        );

    expect(created.id, 7);
    expect(created.status, CityRequestStatus.newRequest);
    expect(server.bodyOf('POST', '/v1/city-edits'), {
      'oldCountryCode': null,
      'newCountryCode': 91,
      'oldName': null,
      'newName': 'Новоград',
      'reason': 'есть в Википедии',
    });
  });

  test('too_many_requests surfaces message', () async {
    server.fail('POST', '/v1/city-edits', 429, 'too_many_requests');

    await expectLater(
      repositoryWith(MemoryTokenStore('token')).sendRemoveRequest(
        oldCountryCode: 91,
        oldCityName: 'Абакан',
        reason: 'нет',
      ),
      throwsA(
        isA<ApiException>()
            .having((e) => e.code, 'code', 'too_many_requests')
            .having(
              (e) => e.message,
              'message',
              'Server says too_many_requests',
            ),
      ),
    );
  });

  for (final code in ['bad_reason', 'bad_request']) {
    test('$code reaches the caller as it is', () async {
      server.fail('POST', '/v1/city-edits', 400, code);

      await expectLater(
        repositoryWith(MemoryTokenStore('token')).sendEditRequest(
          newCountryCode: 91,
          newCityName: 'Абакан-2',
          oldCountryCode: 91,
          oldCityName: 'Абакан',
          reason: 'нет',
        ),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', code)),
      );
    });
  }

  test('a rejected token means the user is not authorized', () {
    server.fail('GET', '/v1/city-edits', 401, 'unauthorized');

    expect(
      repositoryWith(MemoryTokenStore('token')).getRequests(),
      throwsA(isA<NotAuthorizedException>()),
    );
  });

  test('a request without a token fails before it is sent', () async {
    await expectLater(
      repositoryWith(MemoryTokenStore()).getRequests(),
      throwsA(isA<NotAuthorizedException>()),
    );
    expect(server.requests, isEmpty);
  });

  test('a network error is a FetchingException', () {
    server.offline = true;

    expect(
      repositoryWith(MemoryTokenStore('token')).getRequests(),
      throwsA(isA<FetchingException>()),
    );
  });
}
