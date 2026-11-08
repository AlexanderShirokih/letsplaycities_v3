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

  testWidgets('countries are shown by name, unknown codes as they are', (
    tester,
  ) async {
    final set = ScoringSet.initial();
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

  testWidgets('statistics without countries show no data for them', (
    tester,
  ) async {
    await pumpScreen(tester, ScoringSet.initial());

    expect(find.text(t.stats.groups[groupCountries]!), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
