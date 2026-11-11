import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lets_play_cities/base/game/rules/route_leg.dart';
import 'package:lets_play_cities/base/geo/geo_point.dart';
import 'package:lets_play_cities/base/geo/world_outline.dart';
import 'package:lets_play_cities/base/users.dart';

import '../../common/design/app_colors.dart';

/// Shifts every longitude by a multiple of 360 so that the distance to the
/// previous one never exceeds 180 degrees: the route crosses the antimeridian
/// by the short way.
List<double> unwrapLongitudes(List<double> lons) {
  final result = <double>[];

  for (final lon in lons) {
    var value = lon;

    if (result.isNotEmpty) {
      final prev = result.last;

      while (value - prev > 180) {
        value -= 360;
      }

      while (value - prev < -180) {
        value += 360;
      }
    }

    result.add(value);
  }

  return result;
}

/// A straight piece of a flight in degrees: x is the longitude, y the latitude
typedef RouteSegment = ({int leg, Offset from, Offset to});

/// What the map shows of a route: the view and where the cities and the
/// flights between them are, all in degrees (x is the longitude, y the
/// latitude)
class RouteFrame {
  /// The view, already fitted to the aspect of the widget
  final Rect view;

  /// `true` when the route spans so much longitude that the whole world is
  /// shown, the cities are at their real longitudes and flights cross the
  /// edge of the map
  final bool wholeWorld;

  /// The cities in the route order
  final List<Offset> points;

  /// The flights; [RouteSegment.leg] is the index of the city it ends at. A
  /// flight over the edge of the whole world has a second piece on the other
  /// side.
  final List<RouteSegment> segments;

  const RouteFrame({
    required this.view,
    required this.wholeWorld,
    required this.points,
    required this.segments,
  });
}

/// The unwrapped longitudes of a route spanning this much show the whole world
const double routeWholeWorldSpan = 300;

/// The smallest view, so that one city or a short route still shows the
/// coast around it
const routeMinLonSpan = 70.0;
const routeMinLatSpan = 40.0;

const _padding = 0.25;

/// Frames the route through [cities] for a widget of [aspect] (width / height).
///
/// A route that fits into less than [routeWholeWorldSpan] degrees of longitude
/// is framed tightly, crossing the antimeridian by the short way. A longer
/// one, which may circle the globe several times, is shown on the whole world.
RouteFrame routeFrame(List<GeoPoint> cities, double aspect) {
  final lats = [for (final c in cities) c.lat];
  var lons = unwrapLongitudes([for (final c in cities) c.lon]);

  var minLon = -180.0, maxLon = 180.0, minLat = -90.0, maxLat = 90.0;
  var wholeWorld = true;

  if (cities.isNotEmpty) {
    final lonMin = lons.reduce(min);
    final lonMax = lons.reduce(max);
    wholeWorld = lonMax - lonMin >= routeWholeWorldSpan;

    if (!wholeWorld) {
      // Keep the middle of the route on the main copy of the world
      final shift = ((lonMin + lonMax) / 2 / 360).round() * 360.0;
      lons = [for (final lon in lons) lon - shift];

      final lonSpan = max(
        (lonMax - lonMin) * (1 + 2 * _padding),
        routeMinLonSpan,
      );
      final latMin = lats.reduce(min);
      final latMax = lats.reduce(max);
      final latSpan = max(
        (latMax - latMin) * (1 + 2 * _padding),
        routeMinLatSpan,
      );
      final cLon = (lonMin + lonMax) / 2 - shift;
      final cLat = (latMin + latMax) / 2;

      minLon = cLon - lonSpan / 2;
      maxLon = cLon + lonSpan / 2;
      minLat = cLat - latSpan / 2;
      maxLat = cLat + latSpan / 2;
    }
  }

  // Fit the view to the widget aspect by growing the narrower side
  var lonSpan = maxLon - minLon;
  var latSpan = maxLat - minLat;

  if (lonSpan / latSpan < aspect) {
    final grown = latSpan * aspect;
    minLon -= (grown - lonSpan) / 2;
    lonSpan = grown;
  } else {
    final grown = lonSpan / aspect;
    minLat -= (grown - latSpan) / 2;
    latSpan = grown;
  }

  final view = Rect.fromLTWH(minLon, minLat, lonSpan, latSpan);
  final segments = <RouteSegment>[];

  if (!wholeWorld) {
    final points = [
      for (var i = 0; i < cities.length; i++) Offset(lons[i], lats[i]),
    ];

    for (var i = 1; i < points.length; i++) {
      segments.add((leg: i, from: points[i - 1], to: points[i]));
    }

    return RouteFrame(
      view: view,
      wholeWorld: false,
      points: points,
      segments: segments,
    );
  }

  final points = [
    for (var i = 0; i < cities.length; i++)
      Offset((lons[i] + 180) % 360 - 180, lats[i]),
  ];

  for (var i = 1; i < points.length; i++) {
    // The unwrapped step is the short way, never more than 180 degrees
    final from = points[i - 1];
    final to = Offset(from.dx + lons[i] - lons[i - 1], points[i].dy);
    segments.add((leg: i, from: from, to: to));

    // The part past the edge comes back on the other side
    if (to.dx > 180 || to.dx < -180) {
      final shift = Offset(to.dx > 180 ? -360 : 360, 0);
      segments.add((leg: i, from: from + shift, to: to + shift));
    }
  }

  return RouteFrame(
    view: view,
    wholeWorld: true,
    points: points,
    segments: segments,
  );
}

/// The route over the world outline, equirectangular projection
class RouteMap extends StatelessWidget {
  final WorldOutline world;
  final List<RouteLeg> legs;
  final Color Function(User) colorOf;
  final RouteLeg? highlight;
  final String? semanticLabel;

  const RouteMap({
    super.key,
    required this.world,
    required this.legs,
    required this.colorOf,
    this.highlight,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget map = RepaintBoundary(
      child: CustomPaint(
        painter: _RouteMapPainter(
          world: world,
          legs: legs,
          colorOf: colorOf,
          highlight: highlight,
          // The land is a darker violet than the water, in the app palette
          water: isDark
              ? colors.bg
              : Color.lerp(colors.surface, colors.bg, 0.5)!,
          land: Color.lerp(
            isDark ? colors.surface : colors.bg,
            colors.violet,
            isDark ? 0.35 : 0.28,
          )!,
          coast: Color.lerp(
            isDark ? colors.surface : colors.bg,
            colors.violet,
            isDark ? 0.5 : 0.42,
          )!,
          ink: colors.ink,
        ),
        child: const SizedBox.expand(),
      ),
    );

    final label = semanticLabel;

    if (label != null) {
      map = Semantics(label: label, image: true, child: map);
    }

    return ClipRect(child: map);
  }
}

class _RouteMapPainter extends CustomPainter {
  final WorldOutline world;
  final List<RouteLeg> legs;
  final Color Function(User) colorOf;
  final RouteLeg? highlight;
  final Color water, land, coast, ink;

  const _RouteMapPainter({
    required this.world,
    required this.legs,
    required this.colorOf,
    required this.highlight,
    required this.water,
    required this.land,
    required this.coast,
    required this.ink,
  });

  @override
  bool? hitTest(Offset position) => null;

  @override
  SemanticsBuilderCallback? get semanticsBuilder =>
      (_) => const [];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    canvas.clipRect(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, Paint()..color = water);

    final drawn = legs.where((l) => l.point != null).toList();
    final frame = routeFrame([
      for (final l in drawn) l.point!,
    ], size.width / size.height);
    final view = frame.view;
    final scale = size.width / view.width;

    Offset project(Offset deg) => Offset(
      (deg.dx - view.left) * scale,
      size.height - (deg.dy - view.top) / view.height * size.height,
    );

    // The world is repeated so that a route beyond the antimeridian has land
    final landFill = Paint()..color = land;
    final coastLine = Paint()
      ..color = coast
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeJoin = StrokeJoin.round;

    for (final shift in const [-360.0, 0.0, 360.0]) {
      for (final ring in world.rings) {
        if (ring.length < 3) continue;

        final path = Path();

        for (var i = 0; i < ring.length; i++) {
          final p = project(Offset(ring[i].lon + shift, ring[i].lat));
          i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
        }

        path.close();
        canvas.drawPath(path, landFill);
        canvas.drawPath(path, coastLine);
      }
    }

    if (drawn.isEmpty) return;

    // A view wider than 2:1 shows more than one world, so the route of the
    // whole world is repeated with the land
    final copies = frame.wholeWorld ? const [-360.0, 0.0, 360.0] : const [0.0];

    for (final shift in copies) {
      final offset = Offset(shift, 0);

      for (final segment in frame.segments) {
        final leg = drawn[segment.leg];

        canvas.drawLine(
          project(segment.from + offset),
          project(segment.to + offset),
          Paint()
            ..color = colorOf(leg.owner)
            ..strokeWidth = leg == highlight ? 4.5 : 2.5
            ..strokeCap = StrokeCap.round,
        );
      }

      for (var i = 0; i < drawn.length; i++) {
        final isLast = i == drawn.length - 1;
        final point = project(frame.points[i] + offset);
        final color = Paint()..color = colorOf(drawn[i].owner);

        canvas.drawCircle(point, isLast ? 7 : 4, color);

        if (isLast) {
          canvas.drawCircle(
            point,
            7,
            Paint()
              ..color = ink
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_RouteMapPainter old) =>
      old.legs != legs ||
      old.highlight != highlight ||
      old.world != world ||
      old.water != water ||
      old.land != land ||
      old.coast != coast ||
      old.ink != ink;
}
