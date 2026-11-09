import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/game/combo.dart';
import 'package:lets_play_cities/base/game/game_result.dart';
import 'package:lets_play_cities/base/game/game_summary.dart';
import 'package:lets_play_cities/base/game/management.dart';
import 'package:lets_play_cities/base/game/rules/match_rules.dart';
import 'package:lets_play_cities/base/game/rules/route_rules.dart';
import 'package:lets_play_cities/base/geo/geo_index.dart';
import 'package:lets_play_cities/base/geo/geo_point.dart';
import 'package:lets_play_cities/base/users.dart';

import '../../geo/geo_test_data.dart';

class _TestUser extends User {
  _TestUser(String name)
    : super(
        accountInfo: LocalAccountInfo(
          name: name,
          picture: const PlaceholderPictureSource(),
        ),
        comboSystem: ComboSystem(canUseQuickTime: false),
        isTrusted: true,
      );

  @override
  Future<String> onCreateWord(String firstChar) =>
      throw UnimplementedError('not used');
}

void main() {
  // 0x100000 raw is 22.5 degrees of latitude, 0x200000 is 45
  final geo = GeoIndex.parse(
    buildGeoBin([(0, 0), (0x100000, 0), (0x200000, 0)]),
    ['a', 'b', 'c'],
    1,
  );
  final a = geo['a']!;
  final b = geo['b']!;
  final c = geo['c']!;

  late _TestUser first;
  late _TestUser second;
  late RouteRules rules;

  setUp(() {
    first = _TestUser('first');
    second = _TestUser('second');
    rules = RouteRules(geo, 2);
  });

  void accept(User user, String city) =>
      rules.onAccepted(user, city, 0, 0, const {});

  GameResult resultFor(User owner, MoveFinishType type, {User? requester}) =>
      rules.result(
        users: UsersList([first, second]),
        owner: owner,
        finish: OnMoveFinished(type, requester ?? owner),
        summary: GameSummary.empty,
        serverAuthoritative: false,
      );

  test('the first city is 0 km, the next one counts from the previous', () {
    accept(first, 'a');

    expect(first.score, 0);
    expect(rules.state.legs.single.km, 0);
    expect(rules.state.legs.single.point, isNotNull);

    accept(second, 'b');

    expect(second.score, distanceKm(a, b));
    expect(rules.state.legs.last.km, distanceKm(a, b));
    expect(rules.state.km[second], distanceKm(a, b));
    expect(first.score, 0);
  });

  test('a skip keeps km, adds a move and is marked skipped', () {
    accept(first, 'a');
    rules.onSkipped(second);

    expect(rules.state.legs.last.skipped, isTrue);
    expect(rules.state.legs.last.owner, second);
    expect(second.score, 0);
    expect(rules.state.movesDone, 2);
    expect(rules.state.movesOf(second), 1);
    expect(rules.state.movesOf(first), 1);
  });

  test('a timeout is a skip', () {
    expect(rules.onTimeout(first), TimeoutAction.skip);
  });

  test('a skip does not break the chain of known points', () {
    accept(first, 'a');
    rules.onSkipped(second);
    accept(first, 'b');

    expect(first.score, distanceKm(a, b));
  });

  test('an unknown city is 0 km and the next one counts from the last known '
      'point', () {
    accept(first, 'a');
    accept(second, 'unknown');

    expect(second.score, 0);
    expect(rules.state.legs.last.point, isNull);
    expect(rules.state.legs.last.skipped, isFalse);

    accept(first, 'c');

    expect(first.score, distanceKm(a, c));
  });

  test('isOver exactly after 30 moves, accepted and skipped alike', () {
    for (var i = 0; i < 29; i++) {
      if (i.isEven) {
        accept(i % 4 == 0 ? first : second, 'a');
      } else {
        rules.onSkipped(second);
      }
    }

    expect(rules.isOver, isFalse);

    rules.onSkipped(first);

    expect(rules.state.movesDone, 30);
    expect(rules.isOver, isTrue);
  });

  test('countsStats is false', () {
    expect(rules.countsStats, isFalse);
  });

  test('more km wins, fewer loses, with the route in the result', () {
    accept(first, 'a');
    accept(second, 'c');

    final win = resultFor(second, MoveFinishType.routeCompleted);
    final lose = resultFor(first, MoveFinishType.routeCompleted);

    expect(win.matchResult, MatchResult.win);
    expect(lose.matchResult, MatchResult.lose);
    expect(win.hasScore, isTrue);
    expect(win.route, rules.state);
    expect(win.opponent, first);
  });

  test('equal km is a draw', () {
    expect(
      resultFor(first, MoveFinishType.routeCompleted).matchResult,
      MatchResult.draw,
    );
  });

  test('a surrender loses to the requester even with more km', () {
    accept(first, 'a');
    accept(first, 'c');

    final result = resultFor(first, MoveFinishType.surrender, requester: first);

    expect(result.matchResult, MatchResult.lose);
    expect(
      resultFor(second, MoveFinishType.surrender, requester: first).matchResult,
      MatchResult.win,
    );
  });

  test('states gives the current state to a new subscriber', () async {
    accept(first, 'a');

    expect((await rules.states.first).movesDone, 1);

    final seen = <int>[];
    final sub = rules.states.listen((s) => seen.add(s.movesDone));
    await Future<void>.delayed(Duration.zero);
    accept(second, 'b');
    rules.onSkipped(first);
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(seen, [1, 2, 3]);
  });

  test('a combo multiplier does not change the kilometers', () {
    for (var i = 0; i < 4; i++) {
      first.comboSystem.addCity(CityComboInfo.fromMoveParams(0, 'ab', 0));
    }
    expect(first.comboSystem.multiplier, greaterThan(1));

    accept(second, 'a');
    accept(first, 'b');
    accept(second, 'c');
    accept(first, 'a');

    expect(first.score, distanceKm(a, b) + distanceKm(c, a));
    expect(
      first.score,
      rules.state.legs
          .where((leg) => leg.owner == first)
          .fold<int>(0, (sum, leg) => sum + leg.km),
    );
    expect(rules.state.km[first], first.score);
  });

  test('a first city without a point is 0 km and starts no chain', () {
    accept(first, 'unknown');
    accept(second, 'a');

    expect(rules.state.legs.first.point, isNull);
    expect(rules.state.legs.first.skipped, isFalse);
    expect(second.score, 0);

    accept(first, 'b');

    expect(first.score, distanceKm(a, b));
  });

  test('longestLeg is the accepted leg with the most km', () {
    expect(rules.longestLeg, isNull);

    accept(first, 'a');
    rules.onSkipped(second);

    expect(rules.longestLeg!.city, 'a');

    accept(second, 'c');
    accept(first, 'b');

    expect(rules.longestLeg!.km, distanceKm(a, c));
    expect(rules.longestLeg!.owner, second);
  });
}
