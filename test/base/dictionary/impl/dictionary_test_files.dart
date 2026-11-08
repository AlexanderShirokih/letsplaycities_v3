import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

/// Makes `getApplicationSupportDirectory()` return [directory].
/// Pass `null` to remove the fake.
void fakeApplicationSupportDirectory(Directory? directory) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        _pathProviderChannel,
        directory == null ? null : (_) async => directory.path,
      );
}

/// Version of the dictionary bundled in `assets/data/data.db2`.
Future<int> embeddedDictionaryVersion() async {
  final meta = await rootBundle.loadString('assets/data/data.db2.meta');
  return int.parse(RegExp(r'\d+').firstMatch(meta)!.group(0)!);
}

// Code point of cyrillic 'a' minus the byte it is stored as.
const _cyrillicOffset = 0x0430 - 127;

/// Builds a dictionary file in the format `DictionaryFactory` reads:
/// a header, one record per city and a closing record holding the count.
Uint8List buildDictionaryFile(int version, Map<String, int> countryCodes) {
  final bytes = BytesBuilder()
    ..add(
      (ByteData(12)
            ..setUint16(0, 0xFED0)
            ..setUint16(2, 0x01)
            ..setUint32(4, version)
            ..setUint32(8, countryCodes.length))
          .buffer
          .asUint8List(),
    );

  void addRecord(String name, int countryCode) {
    final encoded = [
      for (final char in name.codeUnits)
        char < 127 ? char : char - _cyrillicOffset,
    ];
    bytes
      ..add(
        (ByteData(4)..setUint32(0, encoded.length << 24 | countryCode)).buffer
            .asUint8List(),
      )
      ..add(encoded);
  }

  countryCodes.forEach(addRecord);
  addRecord('${countryCodes.length}cities', 0);

  return bytes.toBytes();
}
