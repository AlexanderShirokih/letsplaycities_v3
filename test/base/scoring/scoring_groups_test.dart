import 'dart:convert';

import 'package:lets_play_cities/base/scoring.dart';
import 'package:test/test.dart';

void main() {
  test('parsing scoring from JSON is correct', () {
    final testString = '''
    {
    'scoringGroups': [
        {
            'main': {
                'type': 'empty',
                'name': 'name'
            },
            'child': [
                {
                    'type': 'int',
                    'name': 'name',
                    'value': 12
                }
            ]
        },
        {
            'main': {
                'type': 'time',
                'name': 'name',
                'value': 12
            },
            'child': [
                {
                    'type': 'paired',
                    'name': 'name',
                    'key': 'key',
                    'value': 123
                },
                 {
                    'type': 'paired',
                    'name': 'name',
                    'key': 'key'
                }
            ]
        }
    ]
}
    ''';

    ScoringSet set;

    expect(() {
      set = ScoringSet.fromJson(json.decode(testString));
    }, returnsNormally);

    expect(set, isNotNull);
    expect(set.groups.length, equals(2));

    expect(set.groups[0].main, equals(ScoringField.empty(name: 'name')));
    expect(set.groups[0].child,
        equals([ScoringField.int(name: 'name', value: 12)]));

    expect(set.groups[1].main, equals(TimeScoringField('name', 12)));
    expect(
        set.groups[1].child,
        equals(
          [
            PairedScoringField('name', 'key', 123),
            ScoringField.paired(name: 'name', value: 'key'),
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

  test('right join works correctly', () {
    final left = ScoringSet(
      groups: [
        ScoringGroup(
          main: ScoringField.empty(name: 'groupA'),
          child: [
            ScoringField.int(name: 'ch1', value: 100),
            ScoringField.int(name: 'ch2', value: 200),
          ],
        )
      ],
    );

    final right = ScoringSet(
      groups: [
        ScoringGroup(
          main: ScoringField.empty(name: 'groupA'),
          child: [
            ScoringField.int(name: 'ch1', value: 10),
            ScoringField.int(name: 'ch2', value: 20),
            ScoringField.int(name: 'ch3', value: 30),
          ],
        ),
        ScoringGroup(
          main: ScoringField.empty(name: 'groupB'),
          child: [
            ScoringField.int(name: 'val1', value: 30),
            ScoringField.int(name: 'val2', value: 40),
          ],
        )
      ],
    );

    final expected = ScoringSet(
      groups: [
        ScoringGroup(
          main: ScoringField.empty(name: 'groupA'),
          child: [
            ScoringField.int(name: 'ch1', value: 100),
            ScoringField.int(name: 'ch2', value: 200),
            ScoringField.int(name: 'ch3', value: 30),
          ],
        ),
        ScoringGroup(
          main: ScoringField.empty(name: 'groupB'),
          child: [
            ScoringField.int(name: 'val1', value: 30),
            ScoringField.int(name: 'val2', value: 40),
          ],
        )
      ],
    );

    expect(left.rightJoin(right), equals(expected));
  });
}
