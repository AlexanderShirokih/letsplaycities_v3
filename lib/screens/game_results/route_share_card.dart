import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:lets_play_cities/base/game/game_result.dart';
import 'package:lets_play_cities/base/game/rules/route_leg.dart';
import 'package:lets_play_cities/base/geo/world_outline.dart';
import 'package:lets_play_cities/base/users.dart';
import 'package:lets_play_cities/i18n/enum_labels.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/common/d2/d2.dart';
import 'package:lets_play_cities/screens/game/route/route_format.dart';
import 'package:lets_play_cities/screens/game/route/route_map.dart';
import 'package:path_provider/path_provider.dart';

/// Side of the picture in logical pixels
const double routeShareCardSize = 360;

/// Pixel ratio of the picture: 360 * 3 = 1080 pixels per side
const double routeShareCardPixelRatio = 3;

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

/// Renders [card] off screen to a 1080x1080 PNG in the temporary directory
/// (the file is overwritten) and returns its path.
///
/// The card is put into the overlay of [context], so it inherits the theme and
/// the translations, and is removed as soon as it is captured.
Future<String> renderRouteShareImage(
  BuildContext context,
  RouteShareCard card,
) async {
  final overlay = Overlay.of(context, rootOverlay: true);
  final boundaryKey = GlobalKey();

  // Placed far outside the screen so the user never sees it
  final entry = OverlayEntry(
    builder: (context) => Positioned(
      left: -routeShareCardSize * 2,
      top: 0,
      width: routeShareCardSize,
      height: routeShareCardSize,
      // The picture has a fixed size, so the text must not grow with the
      // system font size
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
        child: Material(
          type: MaterialType.transparency,
          child: RepaintBoundary(key: boundaryKey, child: card),
        ),
      ),
    ),
  );

  overlay.insert(entry);

  try {
    // Wait for the card to be laid out and painted
    await WidgetsBinding.instance.endOfFrame;

    final boundary =
        boundaryKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: routeShareCardPixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/route_share.png');
    await file.writeAsBytes(data!.buffer.asUint8List(), flush: true);

    return file.path;
  } finally {
    entry.remove();
    entry.dispose();
  }
}
