import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:lets_play_cities/base/dictionary.dart';
import 'package:path_provider/path_provider.dart';

import '../../exceptions.dart';
import 'dictionary_impl.dart';

/// Factory class for creating and loading [DictionaryService] instance
class DictionaryFactory {
  static const _EMBEDDED_DICTIONARY_PATH = "assets/data/data.bin";
  static const _INTERNAL_DICTIONARY_FILE = "/data-last.bin";

  static _Dictionary _cachedDictionary;
  static List<_DictionaryDescriptor> _dictionaryDescriptors;

  static Future<List<_DictionaryDescriptor>> _getDescriptors() async {
    if (_dictionaryDescriptors == null) {
      _dictionaryDescriptors = await _parseDescriptors();
      if (_dictionaryDescriptors.isEmpty)
        throw ("There is no available database descriptors");
    }

    return _dictionaryDescriptors;
  }

  static Future<_DictionaryDescriptor> _getNewestDescriptor() =>
      _getDescriptors().then((list) =>
          (list..sort((a, b) => a.version.compareTo(b.version))).first);

  /// Resets saved dictionary instance and clears underlying data
  static void invalidateCache() {
    _cachedDictionary?.data?.clear();
    _cachedDictionary = null;
    _dictionaryDescriptors = null;
  }

  /// Returns version code of currently installed dictionary
  static Future<int> latestVersion() =>
      _getNewestDescriptor().then((desc) => desc.version);

  static Future<List<_DictionaryDescriptor>> _parseDescriptors() =>
      Stream.fromFutures([
        _getCachedDescriptor(),
        _parseDescriptor(_INTERNAL_DICTIONARY_FILE, true),
        _parseDescriptor(_EMBEDDED_DICTIONARY_PATH, false),
      ]).where((desc) => desc != null).toList();

  static Future<String> _loadDescriptor(bool isInternal, String path) =>
      (isInternal ? File(path).readAsString() : rootBundle.loadString(path));

  static Future<_DictionaryDescriptor> _fromJson(
          dynamic data, String dbPath, bool isInternal) =>
      Future.value(data).then(
        (data) => isInternal
            ? getApplicationSupportDirectory()
                .then((filesDir) => File(filesDir.path + dbPath))
                .then((file) => _InternalDescriptor(file, data['version']))
            : _EmbeddedDescriptor(dbPath, data['version']),
      ); // File

  static Future<_DictionaryDescriptor> _parseDescriptor(
          String dbPath, bool isInternal) =>
      _loadDescriptor(isInternal, "$dbPath.meta")
          .then(jsonDecode)
          .then((data) => _fromJson(data, dbPath, isInternal))
          .catchError((e) => null,
              test: (e) => e
                  is FileSystemException); // File not exists or some parsing error

  static Future<_DictionaryDescriptor> _getCachedDescriptor() async {
    return _cachedDictionary != null
        ? _CacheDescriptor(_cachedDictionary.reset())
        : null;
  }

  /// Loads dictionary in order below:
  ///  1. Cached dictionary
  ///  2. Downloaded dictionary
  ///  3. Embedded dictionary
  Future<DictionaryService> createDictionary() => _getNewestDescriptor()
      .then((desc) => desc.getDictionary())
      .then((dict) => _updateCacheEntry(dict))
      .then((dict) => DictionaryServiceImpl(dict.data));

  _Dictionary _updateCacheEntry(_Dictionary dictionary) {
    if (_cachedDictionary == null)
      _cachedDictionary = dictionary;
    else if (_cachedDictionary.version < dictionary.version) {
      invalidateCache();
      _cachedDictionary = dictionary;
    }
    return dictionary;
  }
}

/// Describes dictionary meta information and way how to load dictionary
abstract class _DictionaryDescriptor {
  final int version;

  const _DictionaryDescriptor(this.version);

  Future<_Dictionary> getDictionary();

  int get order;
}

/// Gets dictionary from given instance
class _CacheDescriptor extends _DictionaryDescriptor {
  final _Dictionary _cached;

  _CacheDescriptor(this._cached) : super(_cached.version);

  @override
  Future<_Dictionary> getDictionary() => Future.value(_cached);

  @override
  int get order => 0;
}

/// Loads dictionary from [File].
class _InternalDescriptor extends _DictionaryDescriptor
    with _DictionaryParserMixin {
  final File _internalFile;

  _InternalDescriptor(this._internalFile, int version) : super(version);

  @override
  Future<_Dictionary> getDictionary() =>
      _internalFile.exists().then((isExists) => isExists ? _parse() : null);

  Future<_Dictionary> _parse() => _internalFile
      .readAsBytes()
      .then((bytes) => bytes.buffer.asByteData())
      .then((byteData) => parseDictionary(byteData, version))
      .catchError((_) => _internalFile.delete().then((_) => null));

  @override
  int get order => 1;
}

/// Loads dictionary from asset bundle
class _EmbeddedDescriptor extends _DictionaryDescriptor
    with _DictionaryParserMixin {
  final String _assetPath;

  _EmbeddedDescriptor(this._assetPath, int version) : super(version);

  @override
  Future<_Dictionary> getDictionary() => rootBundle
      .load(_assetPath)
      .then((data) => parseDictionary(data, version));

  @override
  int get order => 2;
}

/// Contains common methods for dictionary parsing
mixin _DictionaryParserMixin {
  _Dictionary parseDictionary(ByteData data, int expectedVersion) {
    final magic = data.getUint16(0);
    final settings = data.getUint16(2);
    final version = data.getUint32(4);
    final count = data.getUint32(8);

    if (version != expectedVersion)
      throw DictionaryException(
          "Actual dictionary version $version doesn't match with excepted version $expectedVersion",
          -1);
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

  _Dictionary reset() {
    for (final prop in data.values) prop.reset();
    return this;
  }
}
