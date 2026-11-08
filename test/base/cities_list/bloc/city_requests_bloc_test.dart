import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/cities_list/bloc/city_requests_bloc.dart';
import 'package:lets_play_cities/base/cities_list/city_request.dart';
import 'package:lets_play_cities/base/dictionary/country_entity.dart';
import 'package:lets_play_cities/base/repositories/cities/country_repository.dart';
import 'package:lets_play_cities/remote/city_requests_repository.dart';

import '../../repositories/cities/fake_country_loader.dart';

class _FakeCityRequestsRepository implements CityRequestsRepository {
  final List<CityRequest> requests;

  _FakeCityRequestsRepository(this.requests);

  @override
  Future<List<CityRequest>> getRequests() async => requests;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _removeVifleem = CityRequest(
  id: 1,
  oldCountryCode: 70,
  newCountryCode: null,
  oldName: 'вифлеем',
  newName: null,
  reason: 'test',
  verdict: null,
  status: CityRequestStatus.newRequest,
);

const _countries = [
  CountryEntity('Россия', 51, false),
  CountryEntity('Неизвестно', 0, false),
];

void main() {
  test('shows a request whose country is not in the country list', () async {
    final bloc = CityRequestBloc(
      _FakeCityRequestsRepository([_removeVifleem]),
      CountryRepository(
        FakeCountryLoaderFactory(() async => _countries),
        'Неизвестно',
      ),
    );
    await pumpEventQueue();

    final state = bloc.state;
    expect(state, isA<CityRequestItems>());
    expect(
      (state as CityRequestItems).pendingItems.single.source,
      const CityRequestEntity(
        city: 'вифлеем',
        countryName: 'Неизвестно',
        countryCode: 0,
      ),
    );
    await bloc.close();
  });

  test('shows an error when the country list cannot be loaded', () async {
    final bloc = CityRequestBloc(
      _FakeCityRequestsRepository([_removeVifleem]),
      CountryRepository(
        FakeCountryLoaderFactory(() async => throw Exception('no asset')),
        'Неизвестно',
      ),
    );
    await pumpEventQueue();

    expect(bloc.state, isA<CityRequestError>());
    await bloc.close();
  });
}
