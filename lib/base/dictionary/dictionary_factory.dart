import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:lets_play_cities/base/dictionary.dart';
import 'package:lets_play_cities/base/dictionary/dictionary.dart';
import 'package:path_provider/path_provider.dart';

import '../exceptions.dart';

/// Factory interface for creating and loading [DictionaryService] instance
class DictionaryFactory {
  static const _EMBEDDED_DICTIONARY_PATH = "assets/data/data.bin";
  static const _INTERNAL_DICTIONARY_FILE = "/data-last.bin";

  /// Loads downloaded dictionary(preferred), if exists or embedded
  Future<DictionaryService> loadDictionary() async {
    final internal = await _loadInternalDictionary();
    return internal ?? await _loadEmbeddedDictionary();
  }

  Future<DictionaryService> _loadEmbeddedDictionary() async {
    final dictionary = await rootBundle.load(_EMBEDDED_DICTIONARY_PATH);
    final data = _parseDictionary(dictionary);
    return DictionaryServiceImpl(data);
  }

  Future<DictionaryService> _loadInternalDictionary() async {
    final filesDir = await getApplicationSupportDirectory();
    final file = File(filesDir.path + _INTERNAL_DICTIONARY_FILE);
    if (!(await file.exists())) return null;

    try {
      final data =
          _parseDictionary((await file.readAsBytes()).buffer.asByteData());
      return DictionaryServiceImpl(data);
    } on Exception {
      await file.delete();
      return null;
    }
  }

  Map<String, CityProperties> _parseDictionary(ByteData data) {
    final count = data.getUint32(0);
    final countTest = data.getUint32(8);

    if (count != countTest >> 12)
      throw DictionaryException("Invalid file header", -1);

    return _parseData(data, count, 12);
  }

  Map<String, CityProperties> _parseData(ByteData data, int count, int offset) {
    final mapData = HashMap<String, CityProperties>();

    for (int i = 0; i < count + 1; i++) {
      try {
        final length = data.getUint8(offset++);

        final List<int> list = List.generate(
            length, (i) => data.getUint16(offset + i * 2) - 513,
            growable: false);

        offset += length * 2;

        final name = String.fromCharCodes(list);
        final diff = data.getInt8(offset++) - 1;
        final countryCode = data.getInt16(offset);
        offset += 2;
        if (i == count) {
          if (int.parse(name.substring(0, name.length - 6)) != count)
            throw DictionaryException("File checking failed!", i);
        } else
          mapData[name] =
              CityProperties(difficulty: diff, countryCode: countryCode);
      } catch (e) {
        throw DictionaryException("Unknown error: $e", i);
      }
    }

    return mapData;
  }
}
