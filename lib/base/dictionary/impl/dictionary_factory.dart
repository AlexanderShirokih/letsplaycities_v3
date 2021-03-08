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
  static const _EMBEDDED_DICTIONARY_PATH = 'assets/data/data.db2';
  static const _INTERNAL_DICTIONARY_FILE = '/data-last.db2';

  static _Dictionary? _cachedDictionary;

  /// Returns path for internal database file
  static Future<File> get internalDatabaseFile =>
      getApplicationSupportDirectory()
          .then((filesDir) => File(filesDir.path + _INTERNAL_DICTIONARY_FILE));

  static Future<List<_DictionaryDescriptor>> _getDescriptors() async {
    final dictionaryDescriptors = await _parseDescriptors();
    if (dictionaryDescriptors.isEmpty) {
      throw ('There is no available database descriptors');
    }
    return dictionaryDescriptors;
  }

  static Future<_DictionaryDescriptor> _getNewestDescriptor() =>
      _getDescriptors().then((list) => (list
            ..sort((a, b) {
              final vSort = b.version.compareTo(a.version);
              return vSort == 0 ? a.order.compareTo(b.order) : vSort;
            }))
          .first);

  /// Resets saved dictionary instance and clears underlying data
  static void invalidateCache() {
    _cachedDictionary?.data.clear();
    _cachedDictionary = null;
  }

  /// Returns version code of currently installed dictionary
  static Future<int> latestVersion() =>
      _getNewestDescriptor().then((desc) => desc.version);

  static Future<List<_DictionaryDescriptor>> _parseDescriptors() =>
      Stream.fromFutures([
        _getCachedDescriptor(),
        internalDatabaseFile.then((file) => _parseDescriptor(file.path, true)),
        _parseDescriptor(_EMBEDDED_DICTIONARY_PATH, false),
      ])
          .where((desc) => desc != null && desc.isValid())
          .cast<_DictionaryDescriptor>() // Drop nullable part
          .toList();

  static Future<String> _loadDescriptor(bool isInternal, String path) =>
      (isInternal ? File(path).readAsString() : rootBundle.loadString(path));

  static Future<_DictionaryDescriptor> _fromJson(
      Map<String, dynamic> data, String dbPath, bool isInternal) async {
    if (isInternal) {
      return _InternalDescriptor(File(dbPath), data['version']);
    } else {
      return _EmbeddedDescriptor(dbPath, data['version']);
    }
  } // File

  static Future<_DictionaryDescriptor> _parseDescriptor(
          String dbPath, bool isInternal) =>
      _loadDescriptor(isInternal, '$dbPath.meta')
          .then(jsonDecode)
          .then((data) => _fromJson(data, dbPath, isInternal))
          .catchError((e) {},
              test: (e) => e
                  is FileSystemException); // File not exists or some parsing error

  static Future<_DictionaryDescriptor?> _getCachedDescriptor() async {
    return _cachedDictionary != null
        ? _CacheDescriptor(_cachedDictionary!.reset())
        : null;
  }

  /// Loads dictionary in order below:
  ///  1. Cached dictionary
  ///  2. Downloaded dictionary
  ///  3. Embedded dictionary
  Future<DictionaryService> createDictionary() {
    return _getNewestDescriptor()
        .then((desc) => desc.getDictionary())
        .then((dict) => _updateCacheEntry(dict))
        .then((dict) => DictionaryServiceImpl(dict.data));
  }

  _Dictionary _updateCacheEntry(_Dictionary dictionary) {
    if (_cachedDictionary == null) {
      _cachedDictionary = dictionary;
    } else if (_cachedDictionary!.version < (dictionary.version)) {
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

  bool isValid();
}

/// Gets dictionary from given instance
class _CacheDescriptor extends _DictionaryDescriptor {
  final _Dictionary _cached;

  @override
  bool isValid() => true;

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
  bool isValid() => _internalFile.existsSync();

  @override
  Future<_Dictionary> getDictionary() => _internalFile.exists().then(
        (isExists) {
          if (isExists) {
            return _parse();
          } else {
            throw 'Internal dictionary is not exists!';
          }
        },
      );

  Future<_Dictionary> _parse() async {
    try {
      final bytes = await _internalFile.readAsBytes();
      final byteData = bytes.buffer.asByteData();
      return parseDictionary(byteData, version);
    } catch (e) {
      await _internalFile.delete();
      rethrow;
    }
  }

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

  @override
  bool isValid() => true;
}

/// Contains common methods for dictionary parsing
mixin _DictionaryParserMixin {
  _Dictionary parseDictionary(ByteData data, int expectedVersion) {
    final magic = data.getUint16(0);
    final settings = data.getUint16(2);
    final version = data.getUint32(4);
    final count = data.getUint32(8);

    if (version != expectedVersion) {
      throw DictionaryException(
          "Actual dictionary version $version doesn't match with excepted version $expectedVersion",
          -1);
    }
    if (magic != 0xFED0) throw DictionaryException('Invalid file header', -1);
    if (settings != 0x01) {
      throw DictionaryException('Unsupported settings value: $settings', -1);
    }
    return _Dictionary(_parseData(data, count, 12), version);
  }

  // Code point of cyrillic 'a' char + decoding offset
  static const base = 0x0430 - 127;

  Iterable<int> _decodeChars(ByteData data, int offset, int length) sync* {
    for (var i = 0; i < length; i++) {
      final char = data.getUint8(offset + i);
      yield char < 127 ? char : char + base;
    }
  }

  Map<String, CityProperties> _parseData(ByteData data, int count, int offset) {
    final mapData = HashMap<String, CityProperties>();

    for (var i = 0; i < count + 1; i++) {
      try {
        final length = data.getUint8(offset);
        final meta = data.getUint32(offset);
        offset += 4;

        final name = String.fromCharCodes(_decodeChars(data, offset, length));

        offset += length;

        if (i == count) {
          if (int.parse(name.substring(0, name.length - 6)) != count) {
            throw DictionaryException('File checking failed!', i);
          }
        } else {
          mapData[name] = CityProperties.fromBitmask(meta);
        }
      } catch (e) {
        throw DictionaryException('Unknown error: $e', i);
      }
    }

    return mapData;
  }
}

class _Dictionary {
  final Map<String, CityProperties> data;
  final int version;

  const _Dictionary(this.data, this.version);

  _Dictionary reset() {
    for (final prop in data.values) {
      prop.reset();
    }
    return this;
  }
}
