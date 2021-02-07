import 'dart:async';
import 'dart:convert';
import 'dart:io';

// ignore: import_of_legacy_library_into_null_safe
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/base/dictionary/impl/dictionary_factory.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/remote/exceptions.dart';

/// Describes dictionary update period constants
enum DictionaryUpdatePeriod { NEVER, THREE_HOURS, DAILY }

extension DictionaryUpdatePeriodExt on DictionaryUpdatePeriod {
  Duration asDuration() {
    switch (this) {
      case DictionaryUpdatePeriod.NEVER:
        return Duration.zero;
      case DictionaryUpdatePeriod.THREE_HOURS:
        return const Duration(hours: 3);
      case DictionaryUpdatePeriod.DAILY:
        return const Duration(days: 1);
      default:
        throw ('Bad state!');
    }
  }
}

/// [DictionaryUpdater] is responsible for checking dictionary updates and downloading it
class DictionaryUpdater {
  final GamePreferences _prefs;
  final Dio _http;

  DictionaryUpdater()
      : _prefs = GetIt.instance.get<GamePreferences>(),
        _http = GetIt.instance.get<Dio>();

  /// Checks for database updates on game server and downloads it.
  /// If updates disabled or not available no events will be emmited.
  /// When starts fetching update first emits `-1`  value to indicate
  /// fetching update starts. Emits downloading percents from 0 to 100.
  Stream<int> checkForUpdates() {
    final updatePeriod = _prefs.dictionaryUpdatePeriod.asDuration();
    final nextUpdateDate = _prefs.lastDictionaryCheckDate.add(updatePeriod);
    final now = DateTime.now();

    if (updatePeriod == Duration.zero || now.isBefore(nextUpdateDate)) {
      return Stream.empty();
    }

    _prefs.lastDictionaryCheckDate = now;

    return _fetchUpdates().handleError(
      (_) {}, // Eat SocketExceptions
      test: (error) => error is RemoteException,
    );
  }

  Stream<int> _fetchUpdates() async* {
    yield -1; // Begin fetching updates

    final currentVersion = await DictionaryFactory.latestVersion();
    final latestVersion = await _fetchLatestDictionaryVersion()
        .timeout(Duration(seconds: 5), onTimeout: () => 0);

    if (currentVersion >= latestVersion) return;

    // Download database and emit downloading percents
    final databaseFile = await DictionaryFactory.internalDatabaseFile;

    yield* _loadDictionaryData(databaseFile, latestVersion).distinct();

    final isDatabaseExists = await databaseFile.exists();

    if (!isDatabaseExists) {
      return;
    }

    // Build the meta file
    await _buildMeta(File('${databaseFile.path}.meta'), latestVersion);

    // Clear currently loaded cache
    DictionaryFactory.invalidateCache();
  }

  Stream<int> _loadDictionaryData(File output, int latestVersion) async* {
    try {
      final response = await _http.get(
        '/data-$latestVersion.db2',
        options: Options(responseType: ResponseType.stream),
      );

      final total =
          int.parse(response.headers.value(Headers.contentLengthHeader));

      var done = 0;

      final sink = await output.create().then((file) => file.openWrite());

      try {
        await for (final List<int> portion in response.data.stream) {
          done += portion.length;
          sink.add(portion);
          yield (done / total * 100).round();
        }
      } finally {
        await sink.close();
        await sink.done;
      }
    } catch (e) {
      throw RemoteException('Database downloading failed: $e');
    }
  }

  Future<void> _buildMeta(File output, int latestVersion) async {
    await output.writeAsString(jsonEncode({'version': latestVersion}));
  }

  Future<int> _fetchLatestDictionaryVersion() async {
    try {
      final response = await _http.get('/update');

      if (response.statusCode == 200) {
        return response.data['dictionary']['version'] as int;
      }
    } on DioError catch (e) {
      throw FetchingException(
        'Dictionary version fetch error: ${e.error}',
        e.request.uri,
      );
    }

    throw RemoteException('Update fetching failed!');
  }
}
