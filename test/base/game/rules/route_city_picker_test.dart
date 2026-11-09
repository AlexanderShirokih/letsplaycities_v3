import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/dictionary.dart';
import 'package:lets_play_cities/base/game/rules/route_city_picker.dart';
import 'package:lets_play_cities/base/geo/geo_point.dart';

import '../../geo/geo_test_data.dart';

void main() {
  // c0 is the nearest to the origin, c9 the farthest: 0x10000 raw is about
  // 1.4 degrees of latitude
  final names = [for (var i = 0; i < 10; i++) 'c$i'];
  final geo = geoIndexOf({
    'origin': (0, 0),
    for (var i = 0; i < 10; i++) names[i]: ((i + 1) * 0x10000, 0),
  });
  final from = geo['origin'];

  /// Every city [difficulty] picks from [names] over many seeds
  Set<String?> picks(Difficulty difficulty, {GeoPoint? origin}) => {
    for (var seed = 0; seed < 200; seed++)
      pickRouteCity(
        candidates: names.reversed.toList(),
        from: origin,
        geo: geo,
        difficulty: difficulty,
        random: Random(seed),
      ),
  };

  test('hard takes only the farthest city', () {
    expect(picks(Difficulty.hard, origin: from), {'c9'});
  });

  test('medium takes one of the farther half', () {
    expect(picks(Difficulty.medium, origin: from), {
      'c5',
      'c6',
      'c7',
      'c8',
      'c9',
    });
  });

  test('easy takes any city', () {
    expect(picks(Difficulty.easy, origin: from), names.toSet());
  });

  test('without a previous point any city fits', () {
    expect(picks(Difficulty.hard), names.toSet());
  });

  test('a city without a point goes after the ones with it', () {
    final picked = pickRouteCity(
      candidates: ['nowhere', 'c0'],
      from: from,
      geo: geo,
      difficulty: Difficulty.hard,
      random: Random(0),
    );

    expect(picked, 'c0');
  });

  test('no candidates give no city', () {
    final picked = pickRouteCity(
      candidates: const [],
      from: from,
      geo: geo,
      difficulty: Difficulty.easy,
      random: Random(0),
    );

    expect(picked, isNull);
  });
}
