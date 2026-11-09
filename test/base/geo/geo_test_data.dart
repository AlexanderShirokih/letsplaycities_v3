import 'dart:typed_data';

import 'package:lets_play_cities/base/geo/geo_index.dart';
import 'package:lets_play_cities/base/geo/world_outline.dart';

int _crc32(List<int> bytes) {
  var crc = 0xFFFFFFFF;
  for (final b in bytes) {
    crc ^= b;
    for (var k = 0; k < 8; k++) {
      crc = crc & 1 != 0 ? 0xEDB88320 ^ (crc >> 1) : crc >> 1;
    }
  }

  return crc ^ 0xFFFFFFFF;
}

/// Packs points given as raw (lat, lon) i24 values into `geo.bin`
ByteData buildGeoBin(List<(int, int)> raw, {int version = 1}) {
  final out = BytesBuilder();
  out.add(
    (ByteData(12)
          ..setUint16(0, 0x6E0D)
          ..setUint16(2, 1)
          ..setUint32(4, version)
          ..setUint32(8, raw.length))
        .buffer
        .asUint8List(),
  );

  for (final (lat, lon) in raw) {
    for (final v in [lat, lon]) {
      final u = v & 0xFFFFFF;
      out.add([u >> 16, (u >> 8) & 0xFF, u & 0xFF]);
    }
  }

  final body = out.toBytes();
  out.add((ByteData(4)..setUint32(0, _crc32(body))).buffer.asUint8List());

  return ByteData.sublistView(out.toBytes());
}

/// An index of [points] given as raw (lat, lon) i24 values by city name
GeoIndex geoIndexOf(Map<String, (int, int)> points) => GeoIndex.parse(
  buildGeoBin(points.values.toList()),
  points.keys.toList(),
  1,
);

/// A world outline without rings
WorldOutline emptyWorld() => WorldOutline.parse(
  ByteData(6)
    ..setUint16(0, 0x6E0E)
    ..setUint16(2, 1)
    ..setUint16(4, 0),
);
