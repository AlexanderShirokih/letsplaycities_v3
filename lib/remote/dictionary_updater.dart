import 'dart:async';
import 'dart:convert';
import 'dart:io';

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

    _prefs.lastDictionaryCheckDate = now;

    return _fetchUpdates()
        .handleError(
          (_) {}, // Eat SocketExceptions
          test: (error) => error is RemoteException,
        )
        // Repeats are dropped here, not inside [_fetchUpdates]: a cancelled
        // generator stops only at its next `yield`, so every chunk has to
        // reach one.
        .distinct();
  }

  Stream<int> _fetchUpdates() async* {
    yield -1; // Begin fetching updates

    final currentVersion = await DictionaryFactory.latestVersion();
    final latestVersion = await _fetchLatestDictionaryVersion().timeout(
      Duration(seconds: 5),
      onTimeout: () => 0,
    );

    if (currentVersion >= latestVersion) return;

    final databaseFile = await DictionaryFactory.internalDatabaseFile;
    final downloadFile = File('${databaseFile.path}.download');

    // The installed dictionary is replaced only after the new one is fully
    // downloaded and verified, so a failed or cancelled update keeps it.
    try {
      // Not `yield*`: it passes a download error on and then carries on,
      // which would install the incomplete file.
      await for (final percent in _loadDictionaryData(
        downloadFile,
        latestVersion,
      )) {
        yield percent;
      }

      await DictionaryFactory.verifyDictionaryFile(downloadFile, latestVersion);
      await _install(downloadFile, databaseFile, latestVersion);
    } catch (e) {
      throw RemoteException('Database updating failed: $e');
    } finally {
      await _deleteLeftover(downloadFile);
    }
  }

  Stream<int> _loadDictionaryData(File output, int latestVersion) async* {
    final response = await _http.get(
      '/data-$latestVersion.db2',
      options: Options(responseType: ResponseType.stream),
    );

    // `null` when the server does not send Content-Length
    final total = int.tryParse(
      response.headers.value(Headers.contentLengthHeader) ?? '',
    );

    var done = 0;
    yield 0;

    await output.parent.create(recursive: true);
    final sink = output.openWrite();

    try {
      await for (final List<int> portion in response.data.stream) {
        done += portion.length;
        sink.add(portion);
        // Without a size there is no progress to report, but a value per
        // chunk lets a cancelled update stop at the next chunk.
        yield total != null && total > 0
            ? (done * 100 / total).round().clamp(0, 100)
            : 0;
      }
    } finally {
      await sink.close();
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

  Future<int> _fetchLatestDictionaryVersion() async {
    try {
      final response = await _http.get('/update');

      if (response.statusCode == 200) {
        return response.data['dictionary']['version'] as int;
      }
    } on DioException catch (e) {
      throw FetchingException(
        'Dictionary version fetch error: ${e.error}',
        e.requestOptions.uri,
      );
    }

    throw RemoteException('Update fetching failed!');
  }
}
