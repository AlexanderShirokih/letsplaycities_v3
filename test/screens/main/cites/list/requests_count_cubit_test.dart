import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/cities_list/city_request.dart';
import 'package:lets_play_cities/remote/city_requests_repository.dart';
import 'package:lets_play_cities/remote/client/remote_api_client.dart';
import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:lets_play_cities/screens/main/cites/list/requests_count_cubit.dart';

CityRequest _request(int id, CityRequestStatus status) => CityRequest(
  id: id,
  oldCountryCode: null,
  newCountryCode: 91,
  oldName: null,
  newName: 'Город',
  reason: 'причина',
  verdict: null,
  status: status,
);

class _FakeRequests implements CityRequestsRepository {
  final Future<List<CityRequest>> Function() onGet;

  _FakeRequests(this.onGet);

  @override
  Future<List<CityRequest>> getRequests() => onGet();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('requests count counts new requests', () async {
    final cubit = RequestsCountCubit(
      _FakeRequests(
        () async => [
          _request(1, CityRequestStatus.newRequest),
          _request(2, CityRequestStatus.approved),
          _request(3, CityRequestStatus.newRequest),
          _request(4, CityRequestStatus.declined),
        ],
      ),
    );
    addTearDown(cubit.close);

    await cubit.stream.first;

    expect(cubit.state, 2);
  });

  test('requests count is null when not authorized', () async {
    final cubit = RequestsCountCubit(
      _FakeRequests(() async => throw NotAuthorizedException()),
    );
    addTearDown(cubit.close);

    await cubit.refresh();

    expect(cubit.state, isNull);
  });

  test('requests count is null on a network error', () async {
    final cubit = RequestsCountCubit(
      _FakeRequests(() async => throw ConnectionException('offline')),
    );
    addTearDown(cubit.close);

    await cubit.refresh();

    expect(cubit.state, isNull);
  });

  test('requests count drops to null when a refresh fails', () async {
    var fail = false;
    final cubit = RequestsCountCubit(
      _FakeRequests(
        () async => fail
            ? throw StateError('boom')
            : [_request(1, CityRequestStatus.newRequest)],
      ),
    );
    addTearDown(cubit.close);
    await cubit.stream.first;
    expect(cubit.state, 1);

    fail = true;
    await cubit.refresh();

    expect(cubit.state, isNull);
  });
}
