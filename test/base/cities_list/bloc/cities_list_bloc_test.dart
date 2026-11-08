import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/cities_list/bloc/cities_list_bloc.dart';
import 'package:lets_play_cities/base/cities_list/cities_list_entry.dart';
import 'package:lets_play_cities/base/cities_list/cities_list_filter.dart';
import 'package:lets_play_cities/base/dictionary/country_entity.dart';
import 'package:lets_play_cities/base/repositories/cities/city_repository.dart';
import 'package:lets_play_cities/base/repositories/cities/country_repository.dart';

const _russia = 1;
const _australia = 2;

class _FakeCityRepository implements CityRepository {
  @override
  Future<List<CitiesListEntry>> getCityList() async => [
    CitiesListEntry('москва', _russia),
    CitiesListEntry('мосальск', _russia),
    CitiesListEntry('сидней', _australia),
    CitiesListEntry('мельбурн', _australia),
  ];

  @override
  Future<CitiesListEntry?> getCityByName(String city) =>
      throw UnimplementedError();
}

class _FakeCountryRepository implements CountryRepository {
  @override
  Future<List<CountryEntity>> getCountryList() async => const [
    CountryEntity('Россия', _russia, false),
    CountryEntity('Австралия', _australia, false),
  ];

  @override
  Future<CountryEntity> getCountryById(int country) =>
      throw UnimplementedError();
}

void main() {
  late CitiesListBloc bloc;

  setUp(() async {
    bloc = CitiesListBloc(_FakeCityRepository(), _FakeCountryRepository());
    await pumpEventQueue();
  });

  tearDown(() => bloc.close());

  test('keeps a country filter that does not change the shown cities', () async {
    final russiaOnly = CountryListFilter([_russia], false);

    bloc.add(CitiesListUpdateNameFilter('мос'));
    await pumpEventQueue();
    final byName = bloc.state as CitiesListFilteredDataState;

    // Every city starting with 'мос' is in Russia, so the list stays the same.
    bloc.add(CitiesListUpdateCountryFilterEvent(russiaOnly));
    await pumpEventQueue();
    final byNameAndCountry = bloc.state as CitiesListFilteredDataState;

    expect(byNameAndCountry.citiesList, byName.citiesList);
    expect(byNameAndCountry.filter.countryFilter, russiaOnly);

    bloc.add(CitiesListUpdateNameFilter(''));
    await pumpEventQueue();

    final cleared = bloc.state;
    expect(cleared, isA<CitiesListFilteredDataState>());
    expect(
      (cleared as CitiesListDataState).citiesList.map((e) => e.countryCode),
      everyElement(_russia),
    );
  });
}
