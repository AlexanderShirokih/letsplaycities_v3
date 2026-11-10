import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/base/dictionary/country_entity.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/base/repositories/cities/country_repository.dart';
import 'package:lets_play_cities/base/scoring.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/settings/stats/stats_screen.dart';

import '../../../i18n/translations_harness.dart';

class _Prefs extends Fake implements GamePreferences {
  @override
  final String scoringData;

  _Prefs(this.scoringData);
}

class _FakeCountryRepository extends Fake implements CountryRepository {
  @override
  Future<List<CountryEntity>> getCountryList() async => const [
    CountryEntity('Россия', 91, false),
    CountryEntity('Центрально-африканская республика', 236, false),
  ];
}

void main() {
  final t = AppLocale.ru.buildSync();

  setUp(() {
    GetIt.instance.registerSingleton<CountryRepository>(
      _FakeCountryRepository(),
    );
  });

  tearDown(() => GetIt.instance.reset());

  Future<void> pumpScreen(WidgetTester tester, ScoringSet set) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      RepositoryProvider<GamePreferences>.value(
        value: _Prefs(jsonEncode(set.toJson())),
        child: withTranslations(const MaterialApp(home: StatisticsScreen())),
      ),
    );
    await tester.pumpAndSettle();
  }

  ScoringSet withParts(ScoringSet set, {int android = 5}) {
    set[groupParts].main.asIntField().value = android;
    set[groupParts][fieldAndroid].asIntField().value = android;

    return set;
  }

  testWidgets('empty statistics show the empty state', (tester) async {
    await pumpScreen(tester, ScoringSet.initial());

    expect(find.text(t.stats.emptyTitle), findsOneWidget);
    expect(find.text(t.stats.emptyText), findsOneWidget);
    expect(find.text(t.stats.groups[groupCombo]!), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('statistics show the total, modes and hide empty sections', (
    tester,
  ) async {
    final set = withParts(ScoringSet.initial(), android: 74);
    set[groupParts][fieldOnline].asIntField().value = 28;
    set[groupParts].main.asIntField().value = 102;
    set[groupOnline][fieldWins].asIntField().value = 17;
    set[groupOnline][fieldLose].asIntField().value = 11;
    set[groupOnline][fieldTime].asIntField().value = 12 * 3600 + 34 * 60;

    await pumpScreen(tester, set);

    expect(find.text('102'), findsOneWidget);
    expect(find.text(t.stats.games(count: 102)), findsOneWidget);
    expect(find.text(t.stats.fields[fieldAndroid]!), findsOneWidget);
    expect(find.text('74'), findsOneWidget);
    expect(find.text('28'), findsOneWidget);
    // The segments of the mode bar are painted, not collapsed to no height.
    final segment = find
        .descendant(
          of: find.byKey(const ValueKey('stats-mode-bar')),
          matching: find.byType(DecoratedBox),
        )
        .last;
    expect(tester.getSize(segment).height, greaterThan(10));
    expect(find.text(t.stats.wins(count: 17)), findsOneWidget);
    expect(
      find.text(t.stats.durationHm(hours: 12, minutes: 34)),
      findsOneWidget,
    );
    expect(find.text(t.stats.groups[groupCombo]!), findsNothing);
    expect(find.text(t.stats.groups[groupFrequentCities]!), findsNothing);
    expect(find.text(t.stats.groups[groupBigCities]!), findsNothing);
    expect(find.text(t.stats.groups[groupCountries]!), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('time under an hour is shown in minutes', (tester) async {
    final set = withParts(ScoringSet.initial());
    set[groupOnline][fieldTime].asIntField().value = 7 * 60;

    await pumpScreen(tester, set);

    expect(find.text(t.stats.durationM(minutes: 7)), findsOneWidget);
  });

  testWidgets('cities and combo are shown when they have values', (
    tester,
  ) async {
    final set = withParts(ScoringSet.initial());
    set[groupCombo][fieldQuickTime].asIntField().value = 9;
    set[groupFrequentCities].child = [
      const PairedScoringField<String, int>('pval0', 'москва', 31),
      const PairedScoringField<String, int>('pval1', 'астана', 24),
    ];
    set[groupBigCities].child = [
      const PairedScoringField<String, int>('pval0', 'нижний новгород', 15),
    ];

    await pumpScreen(tester, set);

    expect(find.text(t.stats.fields[fieldQuickTime]!), findsOneWidget);
    expect(find.text('Москва'), findsOneWidget);
    expect(find.text('Астана'), findsOneWidget);
    // The cities are stored in lower case
    expect(find.text('Нижний Новгород'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('countries are shown by name, unknown codes as they are', (
    tester,
  ) async {
    final set = withParts(ScoringSet.initial());
    set[groupCountries].child = [
      const PairedScoringField<String, int>('pval0', '91', 3),
      const PairedScoringField<String, int>('pval1', '400', 1),
    ];

    await pumpScreen(tester, set);

    expect(find.text(t.stats.groups[groupCountries]!), findsOneWidget);
    expect(find.text('Россия'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('400'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the more button reveals the rest of the countries', (
    tester,
  ) async {
    final set = withParts(ScoringSet.initial());
    set[groupCountries].child = [
      for (var i = 0; i < 8; i++)
        PairedScoringField<String, int>('pval$i', '${500 + i}', 20 - i),
    ];

    await pumpScreen(tester, set);

    expect(find.text('500'), findsOneWidget);
    expect(find.text('507'), findsNothing);
    expect(find.text(t.profile.moreCountries(count: 3)), findsOneWidget);

    await tester.tap(find.text(t.profile.moreCountries(count: 3)));
    await tester.pumpAndSettle();

    expect(find.text('507'), findsOneWidget);
    expect(find.text(t.profile.moreCountries(count: 3)), findsNothing);
  });

  testWidgets('long names fit a narrow screen with large text', (tester) async {
    tester.view.physicalSize = const Size(320, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final set = withParts(ScoringSet.initial(), android: 12345);
    set[groupOnline][fieldWins].asIntField().value = 123456;
    set[groupOnline][fieldTime].asIntField().value = 99 * 3600;
    set[groupCombo][fieldLongWord].asIntField().value = 12345;
    set[groupFrequentCities].child = [
      const PairedScoringField<String, int>(
        'pval0',
        'Александровск-Сахалинский-Очень-Длинный',
        12345,
      ),
    ];
    set[groupCountries].child = [
      const PairedScoringField<String, int>('pval0', '236', 12345),
    ];

    await tester.pumpWidget(
      RepositoryProvider<GamePreferences>.value(
        value: _Prefs(jsonEncode(set.toJson())),
        child: withTranslations(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!,
            ),
            home: const StatisticsScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Центрально-африканская республика'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
