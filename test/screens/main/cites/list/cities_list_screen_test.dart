import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/base/cities_list/bloc/cities_list_bloc.dart';
import 'package:lets_play_cities/base/cities_list/cities_list_entry.dart';
import 'package:lets_play_cities/base/dictionary/country_entity.dart';
import 'package:lets_play_cities/base/repositories/cities/city_repository.dart';
import 'package:lets_play_cities/base/repositories/cities/country_repository.dart';
import 'package:lets_play_cities/screens/main/cites/list/cities_list_screen.dart';

import '../../../../i18n/translations_harness.dart';

const _russia = 91;

class _FakeCityRepository implements CityRepository {
  @override
  Future<List<CitiesListEntry>> getCityList() async => [
    CitiesListEntry('абакан', _russia),
    CitiesListEntry('бийск', _russia),
    CitiesListEntry('брянск', _russia),
    CitiesListEntry('владимир', _russia),
  ];

  @override
  Future<CitiesListEntry?> getCityByName(String city) =>
      throw UnimplementedError();
}

class _FakeCountryRepository implements CountryRepository {
  @override
  Future<List<CountryEntity>> getCountryList() async => const [
    CountryEntity('Россия', _russia, false),
  ];

  @override
  Future<CountryEntity> getCountryById(int country) =>
      throw UnimplementedError();
}

Finder _expandedCard() => find.byType(Card);

void main() {
  setUp(() {
    GetIt.instance
      ..registerSingleton<CityRepository>(_FakeCityRepository())
      ..registerSingleton<CountryRepository>(_FakeCountryRepository());
  });

  tearDown(() => GetIt.instance.reset());

  testWidgets('expanded city stays the same when the list is filtered', (
    tester,
  ) async {
    await tester.pumpWidget(
      withTranslations(MaterialApp(home: const CitiesListScreen())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Бийск (Россия)'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: _expandedCard(),
        matching: find.text('Бийск (Россия)'),
      ),
      findsOneWidget,
    );

    // Filtering moves 'Бийск' from the second to the first row.
    BlocProvider.of<CitiesListBloc>(tester.element(find.text('Бийск (Россия)')))
        .add(CitiesListUpdateNameFilter('б'));
    await tester.pumpAndSettle();

    expect(find.text('Абакан (Россия)'), findsNothing);
    expect(_expandedCard(), findsOneWidget);
    expect(
      find.descendant(
        of: _expandedCard(),
        matching: find.text('Бийск (Россия)'),
      ),
      findsOneWidget,
    );
  });
}
