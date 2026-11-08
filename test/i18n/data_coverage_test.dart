// The compiler checks every typed key, but not the keys of (map) nodes: the
// app looks those up with ids that exist only at runtime. These tests check
// that every such id has a text.

import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/scoring.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';

void main() {
  final t = AppLocale.ru.buildSync();

  group('stats', () {
    const groupNames = [
      groupCombo,
      groupParts,
      groupOnline,
      groupHiscore,
      groupFrequentCities,
      groupBigCities,
      groupCountries,
    ];

    // fieldPairPrefix is left out: a paired field shows the city name.
    const fieldNames = [
      fieldAndroid,
      fieldPlayer,
      fieldNetwork,
      fieldOnline,
      fieldTime,
      fieldWins,
      fieldLose,
      fieldQuickTime,
      fieldShortWord,
      fieldLongWord,
      fieldSameCountry,
      fieldDiffCountry,
    ];

    test('every group name has a title', () {
      expect(t.stats.groups.keys, containsAll(groupNames));
    });

    test('every field name has a title', () {
      expect(t.stats.fields.keys, containsAll(fieldNames));
    });

    test('every group and field of the initial statistics has a title', () {
      final groups = ScoringSet.initial().groups;
      final fields = [
        for (final group in groups)
          for (final field in group.child)
            if (field is! PairedScoringField) field.name,
      ];

      expect(
        t.stats.groups.keys,
        containsAll(groups.map((group) => group.main.name)),
      );
      expect(t.stats.fields.keys, containsAll(fields));
    });
  });
}
