import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/cities_list/bloc/city_edit_actions_bloc.dart';
import 'package:lets_play_cities/base/cities_list/cities_list_entry.dart';
import 'package:lets_play_cities/base/dictionary/country_entity.dart';
import 'package:lets_play_cities/base/repositories/cities/city_repository.dart';
import 'package:lets_play_cities/base/repositories/cities/country_repository.dart';
import 'package:lets_play_cities/remote/city_requests_repository.dart';

import '../../repositories/cities/fake_country_loader.dart';

class _FakeCityRepository implements CityRepository {
  final Future<CitiesListEntry?> Function(String city) find;

  _FakeCityRepository(this.find);

  @override
  Future<CitiesListEntry?> getCityByName(String city) => find(city);

  @override
  Future<List<CitiesListEntry>> getCityList() => throw UnimplementedError();
}

class _UnusedCityRequestsRepository implements CityRequestsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _countries = [
  CountryEntity('Россия', 51, false),
  CountryEntity('Неизвестно', 0, false),
];

Future<CityEditActionsState> _loadedState({
  required Future<List<CountryEntity>> Function() countries,
  required Future<CitiesListEntry?> Function(String city) findCity,
  String? city,
}) async {
  final bloc = CityEditActionsBloc(
    _UnusedCityRequestsRepository(),
    CountryRepository(FakeCountryLoaderFactory(countries), 'Неизвестно'),
    _FakeCityRepository(findCity),
    'Unknown country',
    city,
  );
  await pumpEventQueue();
  final state = bloc.state;
  await bloc.close();
  return state;
}

void main() {
  test('loads the city with its country', () async {
    final state = await _loadedState(
      countries: () async => _countries,
      findCity: (city) async => CitiesListEntry(city, 51),
      city: 'Москва',
    );

    expect(state, isA<CityEditActionsData>());
    expect((state as CityEditActionsData).cityItem.country, _countries.first);
  });

  test(
    'gives a city with an unlisted country code the unknown country',
    () async {
      final state = await _loadedState(
        countries: () async => _countries,
        findCity: (city) async => CitiesListEntry(city, 70),
        city: 'Москва',
      );

      expect(
        (state as CityEditActionsData).cityItem.country,
        const CountryEntity('Unknown country', 0, false),
      );
    },
  );

  test('reports an error when the country list cannot be loaded', () async {
    final state = await _loadedState(
      countries: () async => throw Exception('no asset'),
      findCity: (city) async => CitiesListEntry(city, 51),
    );

    expect(state, isA<CityDataLoadingError>());
  });

  test('reports an error when the city cannot be looked up', () async {
    final state = await _loadedState(
      countries: () async => _countries,
      findCity: (_) async => throw Exception('dictionary is broken'),
      city: 'Москва',
    );

    expect(state, isA<CityDataLoadingError>());
  });
}
