import 'dart:async';

import 'package:lets_play_cities/base/game/game_result.dart';
import 'package:lets_play_cities/base/game/game_summary.dart';
import 'package:lets_play_cities/base/game/management.dart';
import 'package:lets_play_cities/base/game/rules/match_rules.dart';
import 'package:lets_play_cities/base/game/rules/route_leg.dart';
import 'package:lets_play_cities/base/geo/geo_index.dart';
import 'package:lets_play_cities/base/geo/geo_point.dart';
import 'package:lets_play_cities/base/users.dart';

export 'route_leg.dart';

/// The Route match: a city brings the kilometers from the previous city,
/// a move that ran out of time is skipped, and the game ends when every
/// user has made [movesPerPlayer] moves.
class RouteRules implements MatchRules {
  static const movesPerPlayer = 15;

  final GeoIndex _geo;

  final int _playersCount;

  final _legs = <RouteLeg>[];

  final _km = Map<User, int>.identity();

  final _listeners = <MultiStreamController<RouteState>>{};

  late RouteState _state = _snapshot();

  GeoPoint? _lastPoint;

  RouteRules(this._geo, this._playersCount);

  /// The current state first, then the one after every move
  Stream<RouteState> get states => Stream<RouteState>.multi((listener) {
    listener.add(_state);
    _listeners.add(listener);
    listener.onCancel = () => _listeners.remove(listener);
  }, isBroadcast: true);

  RouteState get state => _state;

  /// The point of the last accepted city that has one, the start of the
  /// next leg
  GeoPoint? get lastPoint => _lastPoint;

  /// The accepted leg with the most kilometers, `null` if there is none
  RouteLeg? get longestLeg {
    RouteLeg? longest;
    for (final leg in _legs) {
      if (!leg.skipped && (longest == null || leg.km > longest.km)) {
        longest = leg;
      }
    }

    return longest;
  }

  @override
  void onAccepted(
    User owner,
    String word,
    int countryCode,
    int moveTimeMs,
    Map<int, int> activeCombos,
  ) {
    final point = _geo[word];
    final previous = _lastPoint;
    final km = point != null && previous != null
        ? distanceKm(previous, point)
        : 0;

    if (point != null) {
      _lastPoint = point;
    }

    // Route has no combos, so the kilometers go to the score as they are
    owner.addPoints(km);
    _km[owner] = (_km[owner] ?? 0) + km;
    _add(
      RouteLeg(
        owner: owner,
        city: word,
        countryCode: countryCode,
        point: point,
        km: km,
      ),
    );
  }

  @override
  TimeoutAction onTimeout(User user) => TimeoutAction.skip;

  @override
  void onSkipped(User user) {
    _km.putIfAbsent(user, () => 0);
    _add(RouteLeg(owner: user, city: null, countryCode: 0, point: null, km: 0));
  }

  @override
  bool get isOver => _legs.length >= movesPerPlayer * _playersCount;

  @override
  bool get countsStats => false;

  @override
  GameResult result({
    required UsersList users,
    required User owner,
    required OnMoveFinished finish,
    required GameSummary summary,
    required bool serverAuthoritative,
  }) => GameResult(
    owner: owner,
    finishType: finish.endType,
    hasScore: true,
    matchResult: finish.endType == MoveFinishType.routeCompleted
        ? _byScore(users, owner)
        : (identical(finish.finishRequester, owner)
              ? MatchResult.lose
              : MatchResult.win),
    finishRequester: finish.finishRequester,
    summary: summary,
    opponent: users.all.where((user) => !identical(user, owner)).firstOrNull,
    route: _state,
  );

  MatchResult _byScore(UsersList users, User owner) {
    final best = users.all.fold<int>(
      0,
      (max, user) => user.score > max ? user.score : max,
    );
    final leaders = users.all.where((user) => user.score == best);

    if (leaders.length == users.all.length) {
      return MatchResult.draw;
    }

    return leaders.any((user) => identical(user, owner))
        ? MatchResult.win
        : MatchResult.lose;
  }

  void _add(RouteLeg leg) {
    _legs.add(leg);
    _state = _snapshot();

    for (final listener in _listeners.toList()) {
      listener.add(_state);
    }
  }

  RouteState _snapshot() => RouteState(
    legs: List.unmodifiable(_legs),
    km: Map<User, int>.identity()..addAll(_km),
    movesDone: _legs.length,
  );
}
