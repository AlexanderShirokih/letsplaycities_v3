import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/geo/geo_point.dart';
import 'package:lets_play_cities/base/geo/route_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const cases = [
    ('любек', 'кадис', 2329),
    ('кадис', 'сегед', 2441),
    ('сегед', 'дамаск', 1969),
    ('дамаск', 'кум', 1348),
    ('кум', 'магнитогорск', 2181),
    ('сантьяго', 'осака', 17609),
    ('москва', 'санкт-петербург', 634),
  ];

  for (final (from, to, expected) in cases) {
    test('$from - $to is about $expected km', () async {
      final data = await RouteData.load();
      final a = data.geo[from];
      final b = data.geo[to];

      expect(a, isNotNull);
      expect(b, isNotNull);
      expect(distanceKm(a!, b!).toDouble(), closeTo(expected, expected * 0.01));
    });
  }

  test('distance to itself is zero', () {
    const p = GeoPoint(10, 20);

    expect(distanceKm(p, p), 0);
  });
}
