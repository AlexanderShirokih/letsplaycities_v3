import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/base/cities_list/bloc/cities_list_bloc.dart';
import 'package:lets_play_cities/base/cities_list/cities_list_entry.dart';
import 'package:lets_play_cities/base/cities_list/city_request.dart';
import 'package:lets_play_cities/base/dictionary/country_entity.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/base/repositories/cities/city_repository.dart';
import 'package:lets_play_cities/base/repositories/cities/country_repository.dart';
import 'package:lets_play_cities/remote/city_requests_repository.dart';
import 'package:lets_play_cities/screens/common/design/design.dart';
import 'package:lets_play_cities/screens/main/cites/list/cities_list_screen.dart';

import '../../../../i18n/translations_harness.dart';

const _russia = 91;
const _spain = 5;

class _FakeCityRepository implements CityRepository {
  @override
  Future<List<CitiesListEntry>> getCityList() async => [
    CitiesListEntry('абакан', _russia),
    CitiesListEntry('абадес', _spain),
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
    CountryEntity('Испания', _spain, false),
  ];

  @override
  Future<CountryEntity> getCountryById(int country) =>
      throw UnimplementedError();
}

class _FakeRequests implements CityRequestsRepository {
  final int pending;

  _FakeRequests(this.pending);

  @override
  Future<List<CityRequest>> getRequests() async => [
    for (var i = 0; i < pending; i++)
      CityRequest(
        id: i,
        oldCountryCode: null,
        newCountryCode: _russia,
        oldName: null,
        newName: 'Город',
        reason: 'причина',
        verdict: null,
        status: CityRequestStatus.newRequest,
      ),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Prefs extends Fake implements GamePreferences {
  @override
  List<int> recentCountries = [];
}

void main() {
  late _Prefs prefs;

  void register({int pending = 0}) {
    GetIt.instance
      ..registerSingleton<CityRepository>(_FakeCityRepository())
      ..registerSingleton<CountryRepository>(_FakeCountryRepository())
      ..registerSingleton<CityRequestsRepository>(_FakeRequests(pending));
    prefs = _Prefs();
  }

  Future<void> pump(WidgetTester tester, {bool narrow = false}) async {
    if (narrow) {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }

    await tester.pumpWidget(
      RepositoryProvider<GamePreferences>.value(
        value: prefs,
        child: withTranslations(
          MaterialApp(
            theme: buildAppTheme(Brightness.light),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(narrow ? 1.3 : 1)),
              child: child!,
            ),
            home: const Scaffold(body: CitiesListScreen()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  tearDown(() => GetIt.instance.reset());

  testWidgets('cities list shows grouped cities and menu', (tester) async {
    register();
    await pump(tester);

    expect(find.text('А'), findsOneWidget);
    expect(find.text('Б'), findsOneWidget);
    expect(find.text('Абакан'), findsOneWidget);
    expect(find.text('Россия'), findsWidgets);
    expect(find.text('Испания'), findsOneWidget);

    await tester.tap(find.byTooltip('Действия: Абакан'));
    await tester.pumpAndSettle();

    expect(find.text('Предложить правку'), findsOneWidget);
    expect(find.text('Предложить удаление'), findsOneWidget);
  });

  testWidgets('cities list is regrouped when it is filtered', (tester) async {
    register();
    await pump(tester);

    BlocProvider.of<CitiesListBloc>(tester.element(find.text('Абакан')))
        .add(CitiesListUpdateNameFilter('б'));
    await tester.pumpAndSettle();

    expect(find.text('А'), findsNothing);
    expect(find.text('Абакан'), findsNothing);
    expect(find.text('Б'), findsOneWidget);
    expect(find.text('Бийск'), findsOneWidget);
    expect(find.text('Брянск'), findsOneWidget);
  });

  testWidgets('search field filters the list by name', (tester) async {
    register();
    await pump(tester);

    await tester.enterText(find.byType(TextField), 'Вла');
    await tester.pumpAndSettle();

    expect(find.text('Владимир'), findsOneWidget);
    expect(find.text('Бийск'), findsNothing);
  });

  testWidgets('requests button shows the number of pending requests', (
    tester,
  ) async {
    register(pending: 2);
    await pump(tester);

    expect(find.text('Мои заявки'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('requests badge is hidden without pending requests', (
    tester,
  ) async {
    register();
    await pump(tester);

    expect(find.text('Мои заявки'), findsOneWidget);
    expect(find.text('0'), findsNothing);
  });

  testWidgets('applied countries filter the list and become recent', (
    tester,
  ) async {
    register();
    await pump(tester);

    await tester.tap(find.text('Все страны'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Испания').last);
    await tester.pump();
    await tester.tap(find.text('Применить'));
    await tester.pumpAndSettle();

    expect(find.text('1 страна'), findsOneWidget);
    expect(find.text('Абадес'), findsOneWidget);
    expect(find.text('Абакан'), findsNothing);
    expect(prefs.recentCountries, [_spain]);
  });

  testWidgets('narrow screen with a large font does not overflow', (
    tester,
  ) async {
    register(pending: 12);
    await pump(tester, narrow: true);

    expect(find.text('Абакан'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Действия: Абакан'));
    await tester.pumpAndSettle();
    expect(find.text('Предложить удаление'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
