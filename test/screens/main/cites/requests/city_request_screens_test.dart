import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/base/cities_list/cities_list_entry.dart';
import 'package:lets_play_cities/base/cities_list/city_request.dart';
import 'package:lets_play_cities/base/dictionary/country_entity.dart';
import 'package:lets_play_cities/base/repositories/cities/city_repository.dart';
import 'package:lets_play_cities/base/repositories/cities/country_repository.dart';
import 'package:lets_play_cities/remote/city_requests_repository.dart';
import 'package:lets_play_cities/screens/common/design/design.dart';
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

/// Requests the fake server answers with
List<CityRequest> _answer = _requests;

final _withdrawn = <int>[];

class _Requests implements CityRequestsRepository {
  @override
  Future<List<CityRequest>> getRequests() async => _answer;

  @override
  Future<void> withdrawRequest(int id) async {
    _withdrawn.add(id);
    _answer = [
      for (final e in _answer)
        if (e.id != id) e,
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _requests = [
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

void main() {
  setUp(() {
    _answer = _requests;
    _withdrawn.clear();

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
          theme: buildAppTheme(Brightness.light),
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

  testWidgets('reviewed request shows its status and the answer', (
    tester,
  ) async {
    await pump(tester, const CityRequestsListScreen());

    expect(find.text('Отклонена'), findsOneWidget);
    expect(find.text('нет такого города'), findsOneWidget);
    expect(
      find.textContaining('На рассмотрении', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('Рассмотренные', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('a pending request is withdrawn after the undo snackbar', (
    tester,
  ) async {
    await pump(tester, const CityRequestsListScreen());

    // Only the pending request has the button
    expect(find.text('Отозвать'), findsOneWidget);

    await tester.tap(find.text('Отозвать'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Абакан'), findsNothing);
    expect(find.text('Заявка отозвана'), findsOneWidget);
    expect(_withdrawn, isEmpty);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(_withdrawn, [1]);
    expect(find.text('Абакан'), findsNothing);
    expect(find.text('Новоград'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('undo keeps the request', (tester) async {
    await pump(tester, const CityRequestsListScreen());

    await tester.tap(find.text('Отозвать'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();

    expect(find.text('Абакан'), findsOneWidget);
    expect(_withdrawn, isEmpty);
  });

  testWidgets('empty list offers to propose a city', (tester) async {
    _answer = const [];

    await pump(tester, const CityRequestsListScreen());

    expect(find.text('Заявок пока нет'), findsOneWidget);
    expect(find.text('Предложить город'), findsOneWidget);
    expect(
      find.textContaining('На рассмотрении', findRichText: true),
      findsNothing,
    );

    await tester.tap(find.text('Предложить город'));
    await tester.pumpAndSettle();

    expect(find.byType(CityEditActionsScreen), findsOneWidget);
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

      final button = tester.widget<AppButton>(find.byType(AppButton).last);
      expect(button.onPressed, isNull);
    });
  }

  testWidgets('send button waits for the reason', (tester) async {
    await pump(tester, const CityEditActionsScreen(action: CityEditAction.add));

    VoidCallback? onPressed() =>
        tester.widget<AppButton>(find.byType(AppButton).last).onPressed;

    await tester.enterText(find.byType(TextField).first, 'Новоград');
    await tester.pumpAndSettle();

    expect(onPressed(), isNull);

    await tester.enterText(find.byType(TextField).last, 'есть в Википедии');
    await tester.pumpAndSettle();

    expect(onPressed(), isNotNull);

    await tester.enterText(find.byType(TextField).last, '');
    await tester.pumpAndSettle();

    expect(onPressed(), isNull);
    expect(
      find.text('Нужно указать причину внесения изменений'),
      findsOneWidget,
    );
  });

  testWidgets('required errors stay hidden until a field is touched', (
    tester,
  ) async {
    await pump(tester, const CityEditActionsScreen(action: CityEditAction.add));

    expect(find.text('Город не должен быть пустым'), findsNothing);
    expect(find.text('Нужно указать причину внесения изменений'), findsNothing);
  });

  testWidgets('remove form offers to propose an edit instead', (tester) async {
    await pump(
      tester,
      const CityEditActionsScreen(
        action: CityEditAction.remove,
        city: 'Абакан',
      ),
    );

    await tester.ensureVisible(find.text('Предложить правку'));
    await tester.tap(find.text('Предложить правку'));
    await tester.pumpAndSettle();

    expect(find.text('Правка города'), findsOneWidget);
  });
}
