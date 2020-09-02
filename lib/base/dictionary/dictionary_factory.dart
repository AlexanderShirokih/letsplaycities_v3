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
  static _Dictionary _cachedDictionary;

  static const _EMBEDDED_DICTIONARY_PATH = "assets/data/data.bin";
  static const _INTERNAL_DICTIONARY_FILE = "/data-last.bin";

  /// Resets saved dictionary instance and clears underlying data
  static void invalidateCache() {
    _cachedDictionary?.data?.clear();
    _cachedDictionary = null;
  }

  /// Loads dictionary in order below:
  ///  1. Cached dictionary
  ///  2. Downloaded dictionary
  ///  3. Embedded dictionary
  Future<DictionaryService> loadDictionary() async {
    final cached = await _loadCachedDictionary();
    final internal = cached ?? await _loadInternalDictionary();
    return internal ?? await _loadEmbeddedDictionary();
  }

  Future<DictionaryService> _loadCachedDictionary() {
    if (_cachedDictionary != null) {
      final data = DictionaryServiceImpl(_cachedDictionary.data);
      data.reset();
      return Future.value(data);
    }
    return Future.value(null);
  }

  Future<DictionaryService> _loadEmbeddedDictionary() async {
    final asset = await rootBundle.load(_EMBEDDED_DICTIONARY_PATH);
    final dictionary = _parseDictionary(asset);
    _updateCacheEntry(dictionary);
    return DictionaryServiceImpl(dictionary.data);
  }

  Future<DictionaryService> _loadInternalDictionary() async {
    final filesDir = await getApplicationSupportDirectory();
    final file = File(filesDir.path + _INTERNAL_DICTIONARY_FILE);
    if (!(await file.exists())) return null;

    try {
      final dictionary =
          _parseDictionary((await file.readAsBytes()).buffer.asByteData());
      _updateCacheEntry(dictionary);
      return DictionaryServiceImpl(dictionary.data);
    } on Exception {
      await file.delete();
      return null;
    }
  }

  void _updateCacheEntry(_Dictionary dictionary) {
    if (_cachedDictionary == null)
      _cachedDictionary = dictionary;
    else if (_cachedDictionary.version < dictionary.version) {
      _cachedDictionary.data.clear();
      _cachedDictionary = dictionary;
    }
  }

  _Dictionary _parseDictionary(ByteData data) {
    final magic = data.getUint16(0);
    final settings = data.getUint16(2);
    final version = data.getUint32(4);
    final count = data.getUint32(8);

    if (magic != 0xFED0) throw DictionaryException("Invalid file header", -1);
    if (settings != 0x01)
      throw DictionaryException("Unsupported settings value: $settings", -1);

    return _Dictionary(_parseData(data, count, 12), version);
  }

  // Code point of cyrillic 'a' char + decoding offset
  static const base = 0x0430 - 127;

  Iterable<int> _decodeChars(ByteData data, int offset, int length) sync* {
    for (int i = 0; i < length; i++) {
      final int char = data.getUint8(offset + i);
      yield char < 127 ? char : char + base;
    }
  }

  Map<String, CityProperties> _parseData(ByteData data, int count, int offset) {
    final mapData = HashMap<String, CityProperties>();

    for (int i = 0; i < count + 1; i++) {
      try {
        final length = data.getUint8(offset);
        final meta = data.getUint32(offset);
        offset += 4;

        final name = String.fromCharCodes(_decodeChars(data, offset, length));

        offset += length;

        if (i == count) {
          if (int.parse(name.substring(0, name.length - 6)) != count)
            throw DictionaryException("File checking failed!", i);
        } else
          mapData[name] = CityProperties.fromBitmask(meta);
      } catch (e) {
        throw DictionaryException("Unknown error: $e", i);
      }
    }

    return mapData;
  }
}

class _Dictionary {
  final Map<String, CityProperties> data;
  final int version;

  const _Dictionary(this.data, this.version)
      : assert(data != null),
        assert(version != null);
}
