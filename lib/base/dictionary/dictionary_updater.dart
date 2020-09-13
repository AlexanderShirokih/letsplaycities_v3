import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/base/dictionary/impl/dictionary_factory.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:http/http.dart' as http;

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
        throw ("Bad state!");
    }
  }
}

/// [DictionaryUpdater] is responsible for checking dictionary updates and downloading it
class DictionaryUpdater {
  final GamePreferences _prefs;
  final http.Client _http;

  DictionaryUpdater(this._prefs, this._http);

  /// Checks for database updates on game server and downloads it.
  /// If updates disabled or not available no events will be emmited.
  /// When starts fetching update first emits `-1`  value to indicate
  /// fetching update starts. Emits downloading percents from 0 to 100.
  Stream<int> checkForUpdates() {
    final updatePeriod = _prefs.dictionaryUpdatePeriod.asDuration();
    final nextUpdateDate = _prefs.lastDictionaryCheckDate.add(updatePeriod);
    final now = DateTime.now();

    if (updatePeriod == Duration.zero || now.isBefore(nextUpdateDate))
      return Stream.empty();

    _prefs.lastDictionaryCheckDate = now;

    return _fetchUpdates().handleError(
      (_) {}, // Eat SocketExceptions
      test: (error) => error is SocketException,
    );
  }

  Stream<int> _fetchUpdates() async* {
    yield -1; // Begin fetching updates

    int latestVersion = await _fetchLatestDictionaryVersion();
    int currentVersion = await DictionaryFactory.latestVersion();

    if (currentVersion >= latestVersion) return;

    // Download database and emit downloading percents
    final databaseFile = await DictionaryFactory.internalDatabaseFile;
    yield* _loadDictionaryData(databaseFile, latestVersion).distinct();

    // Build the meta file
    await _buildMeta(File("${databaseFile.path}.meta"), latestVersion);

    // Clear currently loaded cache
    DictionaryFactory.invalidateCache();
  }

  Stream<int> _loadDictionaryData(File output, int latestVersion) async* {
    final uri =
        Uri.parse("${AppConfig.remotePublicApiURL}/data-$latestVersion.db2");
    final response = await _http.send(http.Request('GET', uri));

    final total = response.contentLength;
    int done = 0;

    final sink = output.openWrite();

    try {
      await for (final portion in response.stream) {
        done += portion.length;
        sink.add(portion);
        yield (done / total * 100).round();
      }
    } finally {
      sink.close();
    }
  }

  Future<void> _buildMeta(File output, int latestVersion) async {
    await output.writeAsString(jsonEncode({'version': latestVersion}));
  }

  Future<int> _fetchLatestDictionaryVersion() async {
    final response = await _http.get("${AppConfig.remotePublicApiURL}/update");

    if (response.statusCode == 200) {
      final resp = jsonDecode(response.body);
      return resp["dictionary"]["version"] as int;
    }

    throw ("Update fetching failed. Status code: ${response.statusCode}");
  }
}
