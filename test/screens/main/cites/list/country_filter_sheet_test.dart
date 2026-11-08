import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/cities_list/cities_list_filter.dart';
import 'package:lets_play_cities/base/dictionary/country_entity.dart';
import 'package:lets_play_cities/screens/common/d2/d2.dart';
import 'package:lets_play_cities/screens/main/cites/list/country_filter_sheet.dart';

import '../../../../i18n/translations_harness.dart';

const _countries = [
  CountryEntity('Россия', 91, false),
  CountryEntity('Испания', 5, false),
  CountryEntity('Казахстан', 70, false),
  CountryEntity('Кабо-Верде', 12, false),
];

void main() {
  CountryListFilter? result;
  var closed = false;

  Future<void> open(
    WidgetTester tester, {
    List<int>? selected,
    List<int> recent = const [],
    bool narrow = false,
  }) async {
    // Tall enough to build every row of the lazy list
    tester.view.physicalSize = narrow
        ? const Size(320, 640)
        : const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    result = null;
    closed = false;

    await tester.pumpWidget(
      withTranslations(
        MaterialApp(
          theme: buildD2Theme(Brightness.light),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(narrow ? 1.3 : 1)),
            child: child!,
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await showCountryFilterSheet(
                    context,
                    countries: _countries,
                    selected: selected,
                    recent: recent,
                  );
                  closed = true;
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('country sheet returns selected codes', (tester) async {
    await open(tester);

    await tester.tap(find.text('Россия'));
    await tester.tap(find.text('Казахстан'));
    await tester.pump();
    await tester.tap(find.text('Применить'));
    await tester.pumpAndSettle();

    expect(result, const CountryListFilter([70, 91], false));
  });

  testWidgets('empty selection means all countries', (tester) async {
    await open(tester);

    await tester.tap(find.text('Применить'));
    await tester.pumpAndSettle();

    expect(result?.isAllPresent, isTrue);
  });

  testWidgets('selecting every country means all countries', (tester) async {
    await open(tester, selected: [91, 5, 70, 12]);

    await tester.tap(find.text('Применить'));
    await tester.pumpAndSettle();

    expect(result?.isAllPresent, isTrue);
  });

  testWidgets('reset clears selection', (tester) async {
    await open(tester, selected: [91, 70]);

    await tester.tap(find.text('Сбросить'));
    await tester.pump();
    await tester.tap(find.text('Применить'));
    await tester.pumpAndSettle();

    expect(result?.isAllPresent, isTrue);
  });

  testWidgets('back closes the sheet without a result', (tester) async {
    await open(tester, selected: [91]);

    await tester.tap(find.byTooltip('Назад'));
    await tester.pumpAndSettle();

    expect(closed, isTrue);
    expect(result, isNull);
  });

  testWidgets('countries are grouped by letter and searchable', (tester) async {
    await open(tester);

    expect(find.text('К'), findsOneWidget);
    expect(find.text('И'), findsOneWidget);
    expect(find.text('Р'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'каз');
    await tester.pumpAndSettle();

    expect(find.text('Казахстан'), findsOneWidget);
    expect(find.text('Россия'), findsNothing);
  });

  testWidgets('recent countries are listed first and share the selection', (
    tester,
  ) async {
    await open(tester, recent: [91, 5]);

    expect(find.text('Недавние'), findsOneWidget);
    expect(find.text('Россия'), findsNWidgets(2));

    await tester.tap(find.text('Россия').first);
    await tester.pump();
    await tester.tap(find.text('Применить'));
    await tester.pumpAndSettle();

    expect(result, const CountryListFilter([91], false));
  });

  testWidgets('narrow screen with a large font does not overflow', (
    tester,
  ) async {
    await open(tester, recent: [91, 5], narrow: true);

    expect(find.text('Недавние'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
