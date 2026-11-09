import 'dart:math';

/// Coordinate in degrees
class GeoPoint {
  final double lat, lon;

  const GeoPoint(this.lat, this.lon);

  @override
  String toString() => 'GeoPoint($lat, $lon)';
}

const _earthRadiusKm = 6371.0;

/// Great-circle distance between [a] and [b] (haversine), in whole kilometers
int distanceKm(GeoPoint a, GeoPoint b) {
  final lat1 = a.lat * pi / 180;
  final lat2 = b.lat * pi / 180;
  final dLat = lat2 - lat1;
  final dLon = (b.lon - a.lon) * pi / 180;

  final h =
      pow(sin(dLat / 2), 2) + cos(lat1) * cos(lat2) * pow(sin(dLon / 2), 2);

  return (2 * _earthRadiusKm * asin(sqrt(h))).round();
}
