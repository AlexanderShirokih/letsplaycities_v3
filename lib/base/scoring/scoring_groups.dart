import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import 'package:lets_play_cities/base/scoring.dart';

/*
 * Group names
 */
const G_COMBO = 'combo';
const G_PARTS = 'tt_n_pts';
const G_ONLINE = 'tt_onl';
const G_HISCORE = 'hscr';
const G_FRQ_CITIES = 'mst_frq_cts';
const G_BIG_CITIES = 'msg_big_cts';

/*
 * Field names
 */
const F_ANDROID = 'pva';
const F_PLAYER = 'pvp';
const F_NETWORK = 'pvn';
const F_ONLINE = 'pvo';
const F_TIME = 'tim';
const F_WINS = 'win';
const F_LOSE = 'los';
const F_P = 'pval';

/*
 * Combo fields names
 */
const F_QUICK_TIME = 'qt';
const F_SHORT_WORD = 'sw';
const F_LONG_WORD = 'lw';
const F_SAME_COUNTRY = 'sc';
const F_DIFF_COUNTRY = 'dc';

/*
 * Empty field value
 */
const V_EMPTY_S = '--';

/// Describes group of [ScoringField]s that have main field and secondary fields.
class ScoringGroup with EquatableMixin {
  final ScoringField main;
  List<ScoringField> child;

  ScoringGroup({@required this.main, this.child});

  ScoringField operator [](String fieldName) =>
      child.singleWhere((element) => element.name == fieldName);

  /// Finds field with [key] in [child] list.
  /// If there is no field with name [key] throws [StateError].
  ScoringField findField(String key) =>
      child.firstWhere((element) => element.name == key);

  Map<String, dynamic> toJson() => {
        'main': main.toJson(),
        'child': child.map((e) => e.toJson()).toList(growable: false)
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
        : List.empty(growable: false);

    return ScoringGroup(main: main, child: child);
  }
}

/// A set of [ScoringGroup]s.
class ScoringSet extends Equatable {
  final List<ScoringGroup> groups;

  ScoringSet({@required this.groups}) : assert(groups != null);

  Map<String, dynamic> toJson() =>
      {'scoringGroups': groups.map((e) => e.toJson()).toList(growable: false)};

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
        groups: right.groups.map((group) {
          final g = _findGroupByName(group.main.name);
          final main = g?.main ?? group.main;
          final child = g == null
              ? group.child
              : group.child
                  .map((field) => _findFieldByName(g, field.name) ?? field)
                  .toList(growable: false);
          return ScoringGroup(main: main, child: child);
        }).toList(growable: false),
      );

  ScoringGroup _findGroupByName(String name) => groups
      .singleWhere((group) => group.main.name == name, orElse: () => null);

  static ScoringField _findFieldByName(ScoringGroup group, String name) =>
      group.child
          .singleWhere((field) => field.name == name, orElse: () => null);

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
            main: ScoringField.int(name: G_PARTS),
            child: [
              ScoringField.int(name: F_ANDROID),
              ScoringField.int(name: F_PLAYER),
              ScoringField.int(name: F_NETWORK),
              ScoringField.int(name: F_ONLINE),
            ],
          ),
          ScoringGroup(
            main: ScoringField.empty(name: G_ONLINE),
            child: [
              ScoringField.time(name: F_TIME),
              ScoringField.int(name: F_WINS),
              ScoringField.int(name: F_LOSE),
            ],
          ),
          ScoringGroup(
            main: ScoringField.empty(name: G_COMBO),
            child: [
              ScoringField.int(name: F_QUICK_TIME),
              ScoringField.int(name: F_SHORT_WORD),
              ScoringField.int(name: F_LONG_WORD),
              ScoringField.int(name: F_SAME_COUNTRY),
              ScoringField.int(name: F_DIFF_COUNTRY),
            ],
          ),
          ScoringGroup(
            main: ScoringField.empty(name: G_FRQ_CITIES),
            child: List.generate(10,
                (i) => ScoringField.paired(name: '$F_P$i', value: V_EMPTY_S),
                growable: false),
          ),
          ScoringGroup(
            main: ScoringField.empty(name: G_BIG_CITIES),
            child: List.generate(10,
                (i) => ScoringField.paired(name: '$F_P$i', value: V_EMPTY_S),
                growable: false),
          ),
        ],
      );
}
