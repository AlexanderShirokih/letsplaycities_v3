import 'package:flutter/material.dart';
import 'package:lets_play_cities/base/game/game_result.dart';
import 'package:lets_play_cities/base/game/rules/route_leg.dart';
import 'package:lets_play_cities/base/geo/world_outline.dart';
import 'package:lets_play_cities/base/users.dart';
import 'package:lets_play_cities/i18n/enum_labels.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/common/d2/d2.dart';
import 'package:lets_play_cities/screens/game/route/route_format.dart';
import 'package:lets_play_cities/screens/game/route/route_map.dart';

/// Side of the picture in logical pixels
const double routeShareCardSize = 360;

/// The text that goes with the route picture: kilometers and countries of
/// [owner] and the game link
String routeShareText(Translations t, RouteState route, User owner) {
  final countries = {
    for (final leg in route.legs)
      if (!leg.skipped && leg.countryCode != 0) leg.countryCode,
  };

  return t.route.shareText(
    km: formatKm(route.km[owner] ?? 0),
    countries: countries.length,
  );
}

/// The picture of the finished route: result, kilometers of the players, the
/// map and the logo
class RouteShareCard extends StatelessWidget {
  final WorldOutline world;

  final RouteState route;

  final User owner;

  final User? opponent;

  final MatchResult matchResult;

  const RouteShareCard({
    super.key,
    required this.world,
    required this.route,
    required this.owner,
    required this.opponent,
    required this.matchResult,
  });

  @override
  Widget build(BuildContext context) {
    final c = D2Colors.of(context);
    final t = context.t;

    return SizedBox(
      width: routeShareCardSize,
      height: routeShareCardSize,
      child: ColoredBox(
        color: c.bg,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const D2Logo(size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      matchResult.label(t),
                      overflow: TextOverflow.ellipsis,
                      style: D2Text.title.copyWith(fontSize: 22, color: c.ink),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              D2Card(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    _row(context, owner),
                    if (opponent != null) ...[
                      const SizedBox(height: 4),
                      _row(context, opponent!),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(color: c.edge, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: RouteMap(
                      world: world,
                      legs: route.legs,
                      colorOf: (user) => routeColorOf(user, c),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, User user) {
    final c = D2Colors.of(context);
    final color = routeKmColorOf(user, c);

    return SizedBox(
      height: 30,
      child: Row(
        children: [
          Expanded(
            child: Text(
              user.name,
              overflow: TextOverflow.ellipsis,
              style: D2Text.body.copyWith(fontSize: 15, color: c.ink),
            ),
          ),
          Text.rich(
            TextSpan(
              style: D2Text.score.copyWith(fontSize: 18, color: color),
              children: [
                TextSpan(text: formatKm(route.km[user] ?? 0)),
                TextSpan(
                  text: '$kmSpace${context.t.route.km}',
                  style: D2Text.small.copyWith(fontSize: 13, color: c.ink),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
