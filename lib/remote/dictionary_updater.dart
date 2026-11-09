import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:lets_play_cities/base/dictionary/dictionary_update_period.dart';
import 'package:lets_play_cities/base/dictionary/impl/dictionary_factory.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/remote/exceptions.dart';

/// [DictionaryUpdater] is responsible for checking dictionary updates and downloading it
class DictionaryUpdater {
  final GamePreferences _prefs;
  final Dio _http;

  /// [_http] fetches from the game server, so its base URL must point there.
  DictionaryUpdater(this._prefs, this._http);

  /// Checks for database updates on game server and downloads it.
  /// If updates disabled or not available no events will be emmited.
  /// When starts fetching update first emits `-1`  value to indicate
  /// fetching update starts. Emits downloading percents from 0 to 100;
  /// when the server does not report the file size only 0 and 100 are emitted.
  Stream<int> checkForUpdates() {
    final updatePeriod = _prefs.dictionaryUpdatePeriod.asDuration();
    final nextUpdateDate = _prefs.lastDictionaryCheckDate.add(updatePeriod);
    final now = DateTime.now();

    if (updatePeriod == Duration.zero || now.isBefore(nextUpdateDate)) {
      return Stream.empty();
    }

    return _fetchUpdates(now)
        .handleError(
          (_) {}, // Eat SocketExceptions
          test: (error) => error is RemoteException,
        )
        // Repeats are dropped here, not inside [_fetchUpdates]: a cancelled
        // generator stops only at its next `yield`, so every chunk has to
        // reach one.
        .distinct();
  }

  Stream<int> _fetchUpdates(DateTime checkTime) async* {
    yield -1; // Begin fetching updates

    final currentVersion = await DictionaryFactory.latestVersion();
    final latest = await _fetchLatestDictionary().timeout(
      Duration(seconds: 5),
      onTimeout: () =>
          throw RemoteException('Dictionary version fetch timeout'),
    );

    // The check has succeeded, even if there is nothing to download. A failed
    // check leaves the date alone, so the next start tries again.
    _prefs.lastDictionaryCheckDate = checkTime;

    if (latest == null || currentVersion >= latest.version) return;

    final databaseFile = await DictionaryFactory.internalDatabaseFile;
    final downloadFile = File('${databaseFile.path}.download');

    // The installed dictionary is replaced only after the new one is fully
    // downloaded and verified, so a failed or cancelled update keeps it.
    try {
      // Not `yield*`: it passes a download error on and then carries on,
      // which would install the incomplete file.
      await for (final percent in _loadDictionaryData(downloadFile, latest)) {
        yield percent;
      }

      await DictionaryFactory.verifyDictionaryFile(
        downloadFile,
        latest.version,
      );
      await _install(downloadFile, databaseFile, latest.version);
    } catch (e) {
      throw RemoteException('Database updating failed: $e');
    } finally {
      await _deleteLeftover(downloadFile);
    }
  }

  /// Downloads the dictionary described by [latest] into [output] and checks
  /// its size and SHA-256. Progress is counted against `latest.size`.
  Stream<int> _loadDictionaryData(File output, _DictionaryInfo latest) async* {
    final response = await _http.get(
      '/dictionary/${latest.version}.db2',
      options: Options(responseType: ResponseType.stream),
    );

    var done = 0;
    yield 0;

    await output.parent.create(recursive: true);
    final sink = output.openWrite();
    final digest = _DigestCatcher();
    final hash = sha256.startChunkedConversion(digest);

    try {
      await for (final List<int> portion in response.data.stream) {
        done += portion.length;
        sink.add(portion);
        hash.add(portion);
        // Every chunk yields, so a cancelled update stops at the next chunk.
        yield latest.size > 0
            ? (done * 100 / latest.size).round().clamp(0, 100)
            : 0;
      }
    } finally {
      await sink.close();
    }

    hash.close();

    if (done != latest.size) {
      throw RemoteException(
        'Dictionary size is $done, expected ${latest.size}',
      );
    }
    if (digest.value.toString() != latest.sha256) {
      throw RemoteException('Dictionary SHA-256 does not match');
    }

    yield 100;
  }

  /// Moves [downloadFile] to [databaseFile] and writes the meta for [version].
  /// The old meta is removed first and the new one appears last, so an
  /// interruption leaves either the old pair or a database without a meta,
  /// which is ignored in favour of the embedded dictionary.
  Future<void> _install(
    File downloadFile,
    File databaseFile,
    int version,
  ) async {
    final meta = File('${databaseFile.path}.meta');
    if (await meta.exists()) await meta.delete();

    await downloadFile.rename(databaseFile.path);

    final metaDraft = File('${meta.path}.download');
    await metaDraft.writeAsString(
      jsonEncode({'version': version}),
      flush: true,
    );
    await metaDraft.rename(meta.path);

    // Clear currently loaded cache
    DictionaryFactory.invalidateCache();
  }

  Future<void> _deleteLeftover(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } on FileSystemException {
      // The next download overwrites it
    }
  }

  /// Reads the description of the dictionary on the server, `null` when the
  /// server has none.
  Future<_DictionaryInfo?> _fetchLatestDictionary() async {
    try {
      final response = await _http.get('/dictionary');
      final data = response.data;

      return _DictionaryInfo(
        data['version'] as int,
        data['size'] as int,
        (data['sha256'] as String).toLowerCase(),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;

      throw FetchingException(
        'Dictionary version fetch error: ${e.error}',
        e.requestOptions.uri,
      );
    } on TypeError catch (e) {
      throw RemoteException('Dictionary description is invalid: $e');
    }
  }
}

/// Version, size and SHA-256 of a dictionary file on the server.
class _DictionaryInfo {
  final int version;
  final int size;
  final String sha256;

  const _DictionaryInfo(this.version, this.size, this.sha256);
}

/// Keeps the digest that a chunked hash conversion ends with.
class _DigestCatcher implements Sink<Digest> {
  late Digest value;

  @override
  void add(Digest data) => value = data;

  @override
  void close() {}
}
