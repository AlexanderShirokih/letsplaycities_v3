import 'package:flutter/material.dart';
import 'package:lets_play_cities/base/game/rules/route_leg.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/common/d2/d2.dart';
import 'package:lets_play_cities/utils/string_utils.dart';

import '../cities_list.dart';
import 'route_format.dart';

/// The last [count] moves of the route, the newest on top: the dot of the
/// player, the city with its letter and the km of the move.
class RouteFeed extends StatelessWidget {
  static const count = 6;

  final List<RouteLeg> legs;

  /// Country names by country code
  final Map<int, String> countryNames;

  const RouteFeed({super.key, required this.legs, required this.countryNames});

  @override
  Widget build(BuildContext context) {
    final c = D2Colors.of(context);
    final last = legs.reversed.take(count).toList(growable: false);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: c.edge, offset: const Offset(0, 3))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < last.length; i++)
            DecoratedBox(
              decoration: BoxDecoration(
                border: i > 0
                    ? Border(top: BorderSide(color: c.bg, width: 2))
                    : null,
              ),
              child: _buildRow(context, c, last[i]),
            ),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, D2Colors c, RouteLeg leg) {
    final t = context.t;
    final city = leg.city;
    final owner = leg.owner.name;

    final dot = Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: routeColorOf(leg.owner, c),
        shape: BoxShape.circle,
        border: Border.all(color: c.ink, width: 2),
      ),
    );

    final List<Widget> content;
    final String label;

    if (city == null) {
      label = '$owner: ${t.route.skipped}';
      content = [
        Expanded(
          child: Text(
            t.route.skipped,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: D2Text.body.copyWith(color: c.inkSoft),
          ),
        ),
      ];
    } else {
      final name = city.toTitleCase();
      label = t.route.feedItem(
        owner: owner,
        city: name,
        country: countryNames[leg.countryCode] ?? t.citiesList.unkCity,
        km: leg.km,
      );
      content = [
        CityFlag(leg.countryCode, width: 22, height: 15),
        Expanded(
          child: Text.rich(
            cityNameSpans(name, c, fontSize: 16),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          '+${formatKm(leg.km)}$kmSpace${t.route.km}',
          maxLines: 1,
          style: D2Text.section.copyWith(
            fontSize: 13,
            color: routeKmColorOf(leg.owner, c),
          ),
        ),
      ];
    }

    return Semantics(
      label: label,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 39),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              dot,
              for (final widget in content) ...[
                const SizedBox(width: 10),
                widget,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
