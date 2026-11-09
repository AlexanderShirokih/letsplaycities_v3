import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/game/combo.dart';
import 'package:lets_play_cities/base/game/rules/route_leg.dart';
import 'package:lets_play_cities/base/geo/geo_point.dart';
import 'package:lets_play_cities/base/geo/world_outline.dart';
import 'package:lets_play_cities/base/users.dart';
import 'package:lets_play_cities/screens/game/route/route_map.dart';

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
  final alice = _TestUser('alice');
  final bob = _TestUser('bob');
  final world = WorldOutline.parse(_worldBytes());

  RouteLeg leg(User owner, String city, GeoPoint? point) =>
      RouteLeg(owner: owner, city: city, countryCode: 1, point: point, km: 100);

  Future<void> pump(
    WidgetTester tester,
    List<RouteLeg> legs, {
    RouteLeg? highlight,
    String? label,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 300,
          height: 200,
          child: RouteMap(
            world: world,
            legs: legs,
            colorOf: (u) => identical(u, alice) ? Colors.red : Colors.blue,
            highlight: highlight,
            semanticLabel: label,
          ),
        ),
      ),
    );
  }

  group('unwrapLongitudes', () {
    test('crosses the antimeridian by the short way', () {
      expect(unwrapLongitudes([-70.6, 135.5]), [-70.6, -224.5]);
    });

    test('keeps close longitudes and handles empty input', () {
      expect(unwrapLongitudes([10, 20, 30]), [10, 20, 30]);
      expect(unwrapLongitudes([]), isEmpty);
    });

    test('accumulates shifts along the route', () {
      expect(unwrapLongitudes([170, -170, 160]), [170, 190, 160]);
    });
  });

  group('routeFrame', () {
    test('frames a short route over the antimeridian tightly', () {
      final frame = routeFrame(const [
        GeoPoint(-33.4, -70.6),
        GeoPoint(34.7, 135.5),
      ], 2);

      expect(frame.wholeWorld, isFalse);
      expect(frame.points.map((p) => p.dx), [-70.6, -224.5]);
      expect(frame.view.left, lessThan(-224.5));
      expect(frame.view.right, greaterThan(-70.6));
      expect(frame.view.width, lessThan(360));
      expect(frame.view.width / frame.view.height, closeTo(2, 1e-9));
      expect(frame.segments, hasLength(1));
      expect(frame.segments.single.from, const Offset(-70.6, -33.4));
      expect(frame.segments.single.to, const Offset(-224.5, 34.7));
    });

    test('keeps the middle of a drifted short route on the main world', () {
      final frame = routeFrame(const [
        GeoPoint(0, 170),
        GeoPoint(0, -100),
        GeoPoint(0, -10),
      ], 2);

      // Unwrapped 170, 260, 350 are moved by a whole turn to -190, -100, -10
      expect(frame.wholeWorld, isFalse);
      expect(frame.points.map((p) => p.dx), [-190, -100, -10]);
      expect(frame.view.center.dx, closeTo(-100, 1e-9));
    });

    test('shows the whole world for a route circling it twice', () {
      final frame = routeFrame(const [
        GeoPoint(10, 0),
        GeoPoint(20, 170),
        GeoPoint(30, -20),
        GeoPoint(40, 150),
        GeoPoint(50, -40),
        GeoPoint(60, 130),
      ], 2);

      expect(frame.wholeWorld, isTrue);
      expect(frame.view, const Rect.fromLTRB(-180, -90, 180, 90));
      expect(frame.points.map((p) => p.dx), [0, 170, -20, 150, -40, 130]);

      // Every flight is 170 degrees to the east; those over the edge come back
      // from the west
      expect(frame.segments.map((s) => (s.leg, s.from.dx, s.to.dx)), [
        (1, 0, 170),
        (2, 170, 340),
        (2, -190, -20),
        (3, -20, 150),
        (4, 150, 320),
        (4, -210, -40),
        (5, -40, 130),
      ]);
    });

    test('flights to the west come back from the east', () {
      final frame = routeFrame(const [
        GeoPoint(0, -170),
        GeoPoint(0, 30),
        GeoPoint(0, -130),
      ], 2);

      // Unwrapped -170, -330, -490 span 320 degrees
      expect(frame.wholeWorld, isTrue);
      expect(frame.segments.map((s) => (s.leg, s.from.dx, s.to.dx)), [
        (1, -170, -330),
        (1, 190, 30),
        (2, 30, -130),
      ]);
    });

    test('shows the coast around a single city', () {
      final frame = routeFrame(const [GeoPoint(55.75, 37.62)], 2);

      expect(frame.wholeWorld, isFalse);
      expect(frame.view.width, greaterThanOrEqualTo(routeMinLonSpan));
      expect(frame.view.height, greaterThanOrEqualTo(routeMinLatSpan));
      expect(frame.view.center, const Offset(37.62, 55.75));
    });

    test('shows the whole world without cities', () {
      final frame = routeFrame(const [], 2);

      expect(frame.view, const Rect.fromLTRB(-180, -90, 180, 90));
      expect(frame.points, isEmpty);
      expect(frame.segments, isEmpty);
    });
  });

  group('RouteMap', () {
    testWidgets('draws an empty route', (tester) async {
      await pump(tester, const []);
      expect(tester.takeException(), isNull);
    });

    testWidgets('draws a single city', (tester) async {
      await pump(tester, [
        leg(alice, 'Santiago', const GeoPoint(-33.4, -70.6)),
      ]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('draws a flight over the antimeridian', (tester) async {
      final legs = [
        leg(alice, 'Santiago', const GeoPoint(-33.4, -70.6)),
        leg(bob, 'Osaka', const GeoPoint(34.7, 135.5)),
        RouteLeg(owner: alice, city: null, countryCode: 0, point: null, km: 0),
        leg(alice, 'Unknown', null),
      ];
      await pump(tester, legs, highlight: legs[1], label: 'Route');
      expect(tester.takeException(), isNull);
      expect(find.bySemanticsLabel('Route'), findsOneWidget);
    });

    testWidgets('draws a route around the whole world', (tester) async {
      await pump(tester, [
        leg(alice, 'A', const GeoPoint(10, 0)),
        leg(bob, 'B', const GeoPoint(20, 170)),
        leg(alice, 'C', const GeoPoint(30, -20)),
        leg(bob, 'D', const GeoPoint(40, 150)),
      ]);
      expect(tester.takeException(), isNull);
    });
  });
}

ByteData _worldBytes() {
  // magic, format, 1 ring of 3 points (lon, lat as int16)
  final data = ByteData(6 + 2 + 3 * 4);
  data.setUint16(0, 0x6E0E);
  data.setUint16(2, 1);
  data.setUint16(4, 1);
  data.setUint16(6, 3);
  final pts = [0, 0, 8000, 0, 8000, 8000];
  for (var i = 0; i < pts.length; i++) {
    data.setInt16(8 + i * 2, pts[i]);
  }

  return data;
}
