import 'dart:convert';

import 'package:lets_play_cities/base/game/scoring/scoring_fields.dart';
import 'package:lets_play_cities/base/game/scoring/scoring_groups.dart';
import 'package:test/test.dart';

void main() {
  test('parsing legacy scoring string is correct', () {
    final testString =
        r"intKey=13<ch1=1|ch2=2>,voidKey<tim=60|zero=0>,paired<pval0=key1=1|noVal=key1|pval1=key>";
    ScoringSet set;

    expect(() {
      set = ScoringSet.fromLegacyString(testString);
    }, returnsNormally);

    expect(set, isNotNull);
    expect(set.groups.length, equals(3));

    expect(set.groups[0].main, equals(IntScoringField("intKey", 13)));
    expect(
        set.groups[0].child,
        equals([
          IntScoringField("ch1", 1),
          IntScoringField("ch2", 2),
        ]));

    expect(set.groups[1].main, equals(EmptyScoringField("voidKey")));
    expect(
        set.groups[1].child,
        equals([
          TimeScoringField("tim", 2),
          IntScoringField("zero", 0),
        ]));

    expect(set.groups[2].main, equals(EmptyScoringField("paired")));
    expect(
        set.groups[2].child,
        equals([
          PairedScoringField<String, int>("pval0", "key1", 1),
          PairedScoringField<String, int>("noVal", "key1", null),
          PairedScoringField<String, int>("pval1", "key", 1),
        ]));
  });

  test('parsing scoring from JSON is correct', () {
    final testString = """
    {
    "scoringGroups": [
        {
            "main": {
                "type": "empty",
                "name": "name"
            },
            "child": [
                {
                    "type": "int",
                    "name": "name",
                    "value": 12
                }
            ]
        },
        {
            "main": {
                "type": "time",
                "name": "name",
                "value": 12
            },
            "child": [
                {
                    "type": "paired",
                    "name": "name",
                    "key": "key",
                    "value": 123
                },
                 {
                    "type": "paired",
                    "name": "name",
                    "key": "key"
                }
            ]
        }
    ]
}
    """;

    ScoringSet set;

    expect(() {
      set = ScoringSet.fromJson(json.decode(testString));
    }, returnsNormally);

    expect(set, isNotNull);
    expect(set.groups.length, equals(2));

    expect(set.groups[0].main, equals(ScoringField.empty(name: "name")));
    expect(set.groups[0].child,
        equals([ScoringField.int(name: "name", value: 12)]));

    expect(set.groups[1].main, equals(TimeScoringField("name", 12)));
    expect(
        set.groups[1].child,
        equals(
          [
            PairedScoringField("name", "key", 123),
            ScoringField.paired(name: "name", value: "key"),
          ],
        ));
  });

  test('test toJson() works correctly', () {
    final initial = ScoringSet.initial();

    expect(initial, isNotNull);

    final jsonData = initial.toJson();
    final recovered = ScoringSet.fromJson(jsonData);

    expect(recovered, isNotNull);
    expect(recovered, equals(initial));
  });
}
