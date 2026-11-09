import 'dart:typed_data';

import 'geo_point.dart';

/// Coordinates of dictionary cities, in the record order of the dictionary
class GeoIndex {
  static const _magic = 0x6E0D;
  static const _format = 1;
  static const _headerSize = 12;
  static const _pointSize = 6;
  static const _scale = 8388608; // 2^23

  final Map<String, GeoPoint> _points;

  const GeoIndex._(this._points);

  /// Parses `geo.bin` that belongs to the dictionary of [dictVersion] with
  /// city [names] in the record order.
  ///
  /// Throws [FormatException] if the data is damaged or doesn't match.
  static GeoIndex parse(ByteData geo, List<String> names, int dictVersion) {
    if (geo.lengthInBytes < _headerSize + 4) {
      throw const FormatException('Geodata is too short');
    }

    if (geo.getUint16(0) != _magic) {
      throw const FormatException('Invalid geodata magic');
    }

    if (geo.getUint16(2) != _format) {
      throw FormatException('Unsupported geodata format ${geo.getUint16(2)}');
    }

    final version = geo.getUint32(4);

    if (version != dictVersion) {
      throw FormatException(
        'Geodata version $version does not match dictionary $dictVersion',
      );
    }

    final count = geo.getUint32(8);

    if (count != names.length) {
      throw FormatException(
        'Geodata count $count does not match dictionary ${names.length}',
      );
    }

    if (geo.lengthInBytes != _headerSize + _pointSize * count + 4) {
      throw const FormatException('Geodata size does not match its count');
    }

    final bodySize = geo.lengthInBytes - 4;
    final body = Uint8List.sublistView(geo, 0, bodySize);

    if (_crc32(body) != geo.getUint32(bodySize)) {
      throw const FormatException('Geodata checksum mismatch');
    }

    final points = <String, GeoPoint>{};
    for (var i = 0; i < count; i++) {
      final offset = _headerSize + _pointSize * i;
      points[names[i]] = GeoPoint(
        _getInt24(geo, offset) * 180 / _scale,
        _getInt24(geo, offset + 3) * 360 / _scale,
      );
    }

    return GeoIndex._(points);
  }

  GeoPoint? operator [](String city) => _points[city];

  int get length => _points.length;

  static int _getInt24(ByteData data, int offset) {
    final value =
        data.getUint8(offset) << 16 |
        data.getUint8(offset + 1) << 8 |
        data.getUint8(offset + 2);

    return value >= 0x800000 ? value - 0x1000000 : value;
  }

  static final _crcTable = List<int>.generate(256, (n) {
    var c = n;
    for (var k = 0; k < 8; k++) {
      c = c & 1 != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
    }

    return c;
  });

  /// CRC-32 (IEEE)
  static int _crc32(Uint8List bytes) {
    var crc = 0xFFFFFFFF;
    for (final b in bytes) {
      crc = _crcTable[(crc ^ b) & 0xFF] ^ (crc >> 8);
    }

    return crc ^ 0xFFFFFFFF;
  }
}
