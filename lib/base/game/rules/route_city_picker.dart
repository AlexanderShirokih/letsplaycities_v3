import 'dart:math';

import 'package:lets_play_cities/base/dictionary.dart';
import 'package:lets_play_cities/base/geo/geo_index.dart';
import 'package:lets_play_cities/base/geo/geo_point.dart';

/// Picks the city of the computer in a Route game from [candidates].
///
/// The candidates are sorted from the farthest from [from] to the nearest,
/// cities without a point go last. A random city is taken from the farthest
/// share that [difficulty] allows: all of them on easy, a half on medium, a
/// tenth on hard. Without [from] any candidate fits. Returns `null` when
/// there are no candidates.
String? pickRouteCity({
  required List<String> candidates,
  required GeoPoint? from,
  required GeoIndex geo,
  required Difficulty difficulty,
  required Random random,
}) {
  if (candidates.isEmpty) return null;

  if (from == null) return candidates[random.nextInt(candidates.length)];

  final distances = {
    for (final city in candidates)
      city: switch (geo[city]) {
        final point? => distanceKm(from, point),
        null => -1,
      },
  };
  final sorted = candidates.toList()
    ..sort((a, b) => distances[b]!.compareTo(distances[a]!));

  final pool = _farthestCount(sorted.length, difficulty);

  return sorted[random.nextInt(pool)];
}

/// `max(1, ceil(n * share))` for the share of [difficulty], in integers so
/// that no rounding error adds a city
int _farthestCount(int n, Difficulty difficulty) {
  final count = switch (difficulty) {
    Difficulty.easy => n,
    Difficulty.medium => (n + 1) ~/ 2,
    Difficulty.hard => (n + 9) ~/ 10,
  };

  return max(1, count);
}
