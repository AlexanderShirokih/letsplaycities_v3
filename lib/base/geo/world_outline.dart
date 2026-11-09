import 'dart:typed_data';

import 'geo_point.dart';

/// Coastline rings of the world map
class WorldOutline {
  static const _magic = 0x6E0E;
  static const _format = 1;

  final List<List<GeoPoint>> rings;

  const WorldOutline._(this.rings);

  /// Parses `world.bin`, throws [FormatException] if the data is damaged
  static WorldOutline parse(ByteData data) {
    try {
      if (data.getUint16(0) != _magic) {
        throw const FormatException('Invalid world outline magic');
      }

      if (data.getUint16(2) != _format) {
        throw FormatException(
          'Unsupported world outline format ${data.getUint16(2)}',
        );
      }

      final ringCount = data.getUint16(4);
      var offset = 6;
      final rings = <List<GeoPoint>>[];

      for (var r = 0; r < ringCount; r++) {
        final pointCount = data.getUint16(offset);
        offset += 2;

        final ring = <GeoPoint>[];
        for (var i = 0; i < pointCount; i++) {
          final lon = data.getInt16(offset);
          final lat = data.getInt16(offset + 2);
          offset += 4;

          ring.add(GeoPoint(lat * 90 / 32767, lon * 180 / 32767));
        }

        rings.add(ring);
      }

      return WorldOutline._(rings);
    } on RangeError {
      throw const FormatException('World outline is truncated');
    }
  }
}
