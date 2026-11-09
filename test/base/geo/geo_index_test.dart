import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/geo/geo_index.dart';
import 'package:lets_play_cities/base/geo/route_data.dart';
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

/// Packs points given as raw (lat, lon) i24 values
ByteData _build(
  List<(int, int)> raw, {
  int magic = 0x6E0D,
  int version = 7,
  int? count,
  bool breakCrc = false,
}) {
  final out = BytesBuilder();
  final header = ByteData(12)
    ..setUint16(0, magic)
    ..setUint16(2, 1)
    ..setUint32(4, version)
    ..setUint32(8, count ?? raw.length);
  out.add(header.buffer.asUint8List());

  for (final (lat, lon) in raw) {
    for (final v in [lat, lon]) {
      final u = v & 0xFFFFFF;
      out.add([u >> 16, (u >> 8) & 0xFF, u & 0xFF]);
    }
  }

  final body = out.toBytes();
  final crc = ByteData(4)..setUint32(0, _crc32(body) ^ (breakCrc ? 1 : 0));
  out.add(crc.buffer.asUint8List());

  return ByteData.sublistView(out.toBytes());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const names = ['a', 'b'];
  // 90 degrees north, 90 degrees west
  final raw = [(0x400000, -0x200000), (-0x200000, 0x100000)];

  test('parses points with sign extension', () {
    final index = GeoIndex.parse(_build(raw), names, 7);

    expect(index.length, 2);
    expect(index['a']!.lat, closeTo(90, 1e-6));
    expect(index['a']!.lon, closeTo(-90, 1e-6));
    expect(index['b']!.lat, closeTo(-45, 1e-6));
    expect(index['b']!.lon, closeTo(45, 1e-6));
    expect(index['c'], isNull);
  });

  test('rejects invalid magic', () {
    expect(
      () => GeoIndex.parse(_build(raw, magic: 0x1234), names, 7),
      throwsFormatException,
    );
  });

  test('rejects broken crc', () {
    expect(
      () => GeoIndex.parse(_build(raw, breakCrc: true), names, 7),
      throwsFormatException,
    );
  });

  test('rejects count that differs from names', () {
    expect(() => GeoIndex.parse(_build(raw), ['a'], 7), throwsFormatException);
    expect(
      () => GeoIndex.parse(_build(raw, count: 3), names, 7),
      throwsFormatException,
    );
  });

  test('rejects another dictionary version', () {
    expect(() => GeoIndex.parse(_build(raw), names, 8), throwsFormatException);
  });

  test('parses world outline', () {
    final data = ByteData(6 + 2 + 8)
      ..setUint16(0, 0x6E0E)
      ..setUint16(2, 1)
      ..setUint16(4, 1)
      ..setUint16(6, 2)
      ..setInt16(8, 32767)
      ..setInt16(10, -32767)
      ..setInt16(12, 0)
      ..setInt16(14, 16384);
    final world = WorldOutline.parse(data);

    expect(world.rings.length, 1);
    expect(world.rings[0][0].lon, closeTo(180, 1e-9));
    expect(world.rings[0][0].lat, closeTo(-90, 1e-9));
    expect(world.rings[0][1].lat, closeTo(45, 0.01));
  });

  test('rejects truncated world outline', () {
    final data = ByteData(8)
      ..setUint16(0, 0x6E0E)
      ..setUint16(2, 1)
      ..setUint16(4, 1)
      ..setUint16(6, 5);

    expect(() => WorldOutline.parse(data), throwsFormatException);
  });

  test('bundled data is consistent', () async {
    final data = await RouteData.load();

    expect(data.world.rings, isNotEmpty);
    expect(data.geo.length, greaterThan(0));
    expect(data.dictionary, isNotNull);
    expect(await RouteData.loadWorld(), same(data.world));
  });
}
