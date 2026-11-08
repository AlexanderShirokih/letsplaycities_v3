import 'package:equatable/equatable.dart';
import 'package:lets_play_cities/base/scoring.dart';

/*
 * Group names
 */
const groupCombo = 'combo';
const groupParts = 'tt_n_pts';
const groupOnline = 'tt_onl';
const groupHiscore = 'hscr';
const groupFrequentCities = 'mst_frq_cts';
const groupBigCities = 'msg_big_cts';

/*
 * Field names
 */
const fieldAndroid = 'pva';
const fieldPlayer = 'pvp';
const fieldNetwork = 'pvn';
const fieldOnline = 'pvo';
const fieldTime = 'tim';
const fieldWins = 'win';
const fieldLose = 'los';
const fieldPairPrefix = 'pval';

/*
 * Combo fields names
 */
const fieldQuickTime = 'qt';
const fieldShortWord = 'sw';
const fieldLongWord = 'lw';
const fieldSameCountry = 'sc';
const fieldDiffCountry = 'dc';

/*
 * Empty field value
 */
const emptyFieldValue = '--';

/// Describes group of [ScoringField]s that have main field and secondary fields.
// ignore: must_be_immutable
class ScoringGroup with Equatable {
  final ScoringField main;
  List<ScoringField> child;

  ScoringGroup({required this.main, required this.child});

  ScoringField operator [](String fieldName) =>
      child.singleWhere((element) => element.name == fieldName);

  /// Finds field with [key] in [child] list.
  /// If there is no field with name [key] throws [StateError].
  ScoringField findField(String key) =>
      child.firstWhere((element) => element.name == key);

  Map<String, dynamic> toJson() => {
    'main': main.toJson(),
    'child': child.map((e) => e.toJson()).toList(growable: false),
  };

  @override
  List<Object> get props => [main, child];

  @override
  bool get stringify => true;

  factory ScoringGroup.fromJson(Map<String, dynamic> group) {
    final main = group['main'] != null
        ? ScoringField.fromJson(group['main'])
        : throw ('No main field provided in group: $group');

    final child = group['child'] != null
        ? (group['child'] as List<dynamic>)
              .map((element) => ScoringField.fromJson(element))
              .toList(growable: false)
        : List<ScoringField>.empty(growable: false);

    return ScoringGroup(main: main, child: child);
  }
}

/// A set of [ScoringGroup]s.
class ScoringSet extends Equatable {
  final List<ScoringGroup> groups;

  const ScoringSet({required this.groups});

  Map<String, dynamic> toJson() => {
    'scoringGroups': groups.map((e) => e.toJson()).toList(growable: false),
  };

  @override
  List<Object> get props => [groups];

  @override
  bool get stringify => true;

  ScoringGroup operator [](String groupName) =>
      groups.singleWhere((element) => element.main.name == groupName);

  /// Returns new [ScoringSet] containing fields both from [right] and this set,
  /// and unique from [right] set.
  /// Replaces [right] field values with this field values if they don't equal.
  /// For example (pseudo code):
  /// a = ScoringSet('group1': 'val1', 'group2': 'val2', 'group3': 'val3')
  /// b = ScoringSet('group2' : 'val3')
  /// c = b.rightJoin(a)
  /// c == ScoringSet('group1': 'val1', 'group2': 'val3', 'group3': 'val3')
  ScoringSet rightJoin(ScoringSet right) => ScoringSet(
    groups: right.groups
        .map((group) {
          final g = _findGroupByName(group.main.name);
          final main = g?.main ?? group.main;
          final child = g == null
              ? group.child
              : group.child
                    .map((field) => _findFieldByName(g, field.name) ?? field)
                    .toList(growable: false);
          return ScoringGroup(main: main, child: child);
        })
        .toList(growable: false),
  );

  ScoringGroup? _findGroupByName(String name) {
    try {
      return groups.singleWhere((group) => group.main.name == name);
    } on StateError {
      return null;
    }
  }

  static ScoringField? _findFieldByName(ScoringGroup group, String name) {
    try {
      return group.child.singleWhere((field) => field.name == name);
    } on StateError {
      return null;
    }
  }

  factory ScoringSet.fromJson(Map<String, dynamic> data) {
    return ScoringSet(
      groups: (data['scoringGroups'] as List<dynamic>)
          .map((e) => ScoringGroup.fromJson(e))
          .toList(growable: false),
    );
  }

  factory ScoringSet.initial() => ScoringSet(
    groups: [
      ScoringGroup(
        main: ScoringField.int(name: groupParts),
        child: [
          ScoringField.int(name: fieldAndroid),
          ScoringField.int(name: fieldPlayer),
          ScoringField.int(name: fieldNetwork),
          ScoringField.int(name: fieldOnline),
        ],
      ),
      ScoringGroup(
        main: ScoringField.empty(name: groupOnline),
        child: [
          ScoringField.time(name: fieldTime),
          ScoringField.int(name: fieldWins),
          ScoringField.int(name: fieldLose),
        ],
      ),
      ScoringGroup(
        main: ScoringField.empty(name: groupCombo),
        child: [
          ScoringField.int(name: fieldQuickTime),
          ScoringField.int(name: fieldShortWord),
          ScoringField.int(name: fieldLongWord),
          ScoringField.int(name: fieldSameCountry),
          ScoringField.int(name: fieldDiffCountry),
        ],
      ),
      ScoringGroup(
        main: ScoringField.empty(name: groupFrequentCities),
        child: List.generate(
          10,
          (i) => ScoringField.paired(
            name: '$fieldPairPrefix$i',
            value: emptyFieldValue,
          ),
          growable: false,
        ),
      ),
      ScoringGroup(
        main: ScoringField.empty(name: groupBigCities),
        child: List.generate(
          10,
          (i) => ScoringField.paired(
            name: '$fieldPairPrefix$i',
            value: emptyFieldValue,
          ),
          growable: false,
        ),
      ),
    ],
  );
}
