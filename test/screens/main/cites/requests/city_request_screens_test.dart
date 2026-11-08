import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/base/cities_list/cities_list_entry.dart';
import 'package:lets_play_cities/base/cities_list/city_request.dart';
import 'package:lets_play_cities/base/dictionary/country_entity.dart';
import 'package:lets_play_cities/base/repositories/cities/city_repository.dart';
import 'package:lets_play_cities/base/repositories/cities/country_repository.dart';
import 'package:lets_play_cities/remote/city_requests_repository.dart';
import 'package:lets_play_cities/screens/common/d2/d2.dart';
import 'package:lets_play_cities/screens/main/cites/model/city_edit_action.dart';
import 'package:lets_play_cities/screens/main/cites/requests/city_edit_actions_screen.dart';
import 'package:lets_play_cities/screens/main/cites/requests/city_requests_list_screen.dart';

import '../../../../i18n/translations_harness.dart';

const _russia = 91;

class _Cities implements CityRepository {
  @override
  Future<List<CitiesListEntry>> getCityList() async => [];

  @override
  Future<CitiesListEntry?> getCityByName(String city) async =>
      CitiesListEntry(city, _russia);
}

class _Countries implements CountryRepository {
  @override
  Future<List<CountryEntity>> getCountryList() async => const [
    CountryEntity('Россия', _russia, false),
  ];

  @override
  Future<CountryEntity> getCountryById(int country) async =>
      const CountryEntity('Россия', _russia, false);
}

class _Requests implements CityRequestsRepository {
  @override
  Future<List<CityRequest>> getRequests() async => const [
    CityRequest(
      id: 1,
      oldCountryCode: _russia,
      newCountryCode: _russia,
      oldName: 'Абакан',
      newName: 'Абакан-2',
      reason: 'опечатка',
      verdict: null,
      status: CityRequestStatus.newRequest,
    ),
    CityRequest(
      id: 2,
      oldCountryCode: null,
      newCountryCode: _russia,
      oldName: null,
      newName: 'Новоград',
      reason: 'есть в Википедии',
      verdict: 'нет такого города',
      status: CityRequestStatus.declined,
    ),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    GetIt.instance
      ..registerSingleton<CityRepository>(_Cities())
      ..registerSingleton<CountryRepository>(_Countries())
      ..registerSingleton<CityRequestsRepository>(_Requests());

    addTearDown(GetIt.instance.reset);
  });

  Future<void> pump(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      withTranslations(
        MaterialApp(
          theme: buildD2Theme(Brightness.light),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: screen,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('requests list shows pending and reviewed requests', (
    tester,
  ) async {
    await pump(tester, const CityRequestsListScreen());

    expect(find.text('Абакан'), findsOneWidget);
    expect(find.text('Новоград'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final action in CityEditAction.values) {
    testWidgets('${action.name} form fits a narrow screen and sends only '
        'a filled form', (tester) async {
      await pump(
        tester,
        CityEditActionsScreen(
          action: action,
          city: action == CityEditAction.add ? null : 'Абакан',
        ),
      );

      expect(find.text('Отправить'), findsOneWidget);
      expect(tester.takeException(), isNull);

      final button = tester.widget<D2Button>(find.byType(D2Button));
      expect(button.onPressed, isNull);
    });
  }
}
