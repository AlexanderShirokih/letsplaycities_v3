import 'dart:convert';

import 'package:lets_play_cities/base/dictionary.dart';
import 'package:lets_play_cities/base/scoring.dart';
import 'package:lets_play_cities/base/themes/app_theme_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How many countries the cities filter remembers as recent
const maxRecentCountries = 5;

/// Represents application preferences
abstract class GamePreferences {
  /// Words difficulty level.
  Difficulty get wordsDifficulty;

  /// Theme mode chosen by the user. [AppThemeMode.system] by default.
  AppThemeMode get themeMode;

  set themeMode(AppThemeMode mode);

  set wordsDifficulty(Difficulty d);

  /// `true` when words spelling correction is enabled.
  bool get correctionEnabled;

  set correctionEnabled(bool b);

  /// `true` when game sound is enabled.
  bool get soundEnabled;

  set soundEnabled(bool b);

  /// `true` when chat in network mode is enabled.
  bool get onlineChatEnabled;

  set onlineChatEnabled(bool b);

  /// Time limit per users move in local game modes.
  /// `0` means timer is disabled. Measured in seconds.
  int get timeLimit;

  set timeLimit(int i);

  /// Defines game score calculation and winner checking strategy.
  ScoringType get scoringType;

  set scoringType(ScoringType s);

  /// Returns string containing JSON-encoded representation of score data.
  String get scoringData;

  set scoringData(String s);

  /// Last dictionary updates checking date.
  DateTime get lastDictionaryCheckDate;

  set lastDictionaryCheckDate(DateTime d);

  /// Gets dictionary update checking interval.
  /// [DictionaryUpdatePeriod.never] means don't fetch updates.
  DictionaryUpdatePeriod get dictionaryUpdatePeriod;

  set dictionaryUpdatePeriod(DictionaryUpdatePeriod dup);

  /// Is there a first application launch?
  /// After first calls sets to false
  bool get isFirstLaunch;

  String get lastNativeLogin;

  set lastNativeLogin(String newLogin);

  /// `true` after the user signed out of the online account, until the next
  /// sign-in. The device account is not signed in silently meanwhile.
  bool get signedOut;

  set signedOut(bool value);

  /// Names of the first and the second player in the last game of two
  /// players on one device. Empty until the first such game.
  List<String> get hotseatNames;

  set hotseatNames(List<String> names);

  /// Country codes of the last applied cities filters, the latest first,
  /// at most [maxRecentCountries]
  List<int> get recentCountries;

  set recentCountries(List<int> codes);

  /// Local progress of each achievement by its wire name: the sum of its
  /// increments. Empty until the first achievement is unlocked.
  Map<String, int> get achievementsProgress;

  set achievementsProgress(Map<String, int> progress);
}

class SharedPreferencesGamePrefs extends GamePreferences {
  final SharedPreferences _prefs;

  SharedPreferencesGamePrefs(this._prefs);

  /// Opens the preferences of an app launch. The old Basic-auth keys are
  /// erased without migration: the access token lives in the secure storage
  /// now, so a signed-in user signs in once more.
  static Future<SharedPreferencesGamePrefs> open(
    SharedPreferences prefs,
  ) async {
    await prefs.remove('uid');
    await prefs.remove('uhash');
    return SharedPreferencesGamePrefs(prefs);
  }

  @override
  Difficulty get wordsDifficulty =>
      Difficulty.values[(_prefs.getInt('wordsDifficulty') ?? 0)];

  @override
  set wordsDifficulty(Difficulty d) =>
      _prefs.setInt('wordsDifficulty', d.index);

  @override
  bool get correctionEnabled => _prefs.getBool('correctionEnabled') ?? true;

  @override
  set correctionEnabled(bool b) => _prefs.setBool('correctionEnabled', b);

  @override
  bool get soundEnabled => _prefs.getBool('soundEnabled') ?? true;

  @override
  set soundEnabled(bool b) => _prefs.setBool('soundEnabled', b);

  @override
  bool get onlineChatEnabled => _prefs.getBool('onlineChatEnabled') ?? true;

  @override
  set onlineChatEnabled(bool b) => _prefs.setBool('onlineChatEnabled', b);

  @override
  int get timeLimit => _prefs.getInt('timeLimit') ?? 60;

  @override
  set timeLimit(int i) => _prefs.setInt('timeLimit', i);

  @override
  ScoringType get scoringType =>
      ScoringType.values[_prefs.getInt('scoringType') ?? 0];

  @override
  set scoringType(ScoringType s) => _prefs.setInt('scoringType', s.index);

  @override
  String get scoringData => _prefs.getString('scoringData') == null
      ? ''
      : utf8.decode(base64.decode(_prefs.getString('scoringData')!));

  @override
  set scoringData(String s) =>
      _prefs.setString('scoringData', base64.encode(utf8.encode(s)));

  @override
  DateTime get lastDictionaryCheckDate => DateTime.fromMillisecondsSinceEpoch(
    _prefs.getInt('lastDictionaryCheckDate') ?? 0,
  );

  @override
  set lastDictionaryCheckDate(DateTime d) =>
      _prefs.setInt('lastDictionaryCheckDate', d.millisecondsSinceEpoch);

  @override
  DictionaryUpdatePeriod get dictionaryUpdatePeriod =>
      DictionaryUpdatePeriod.values[_prefs.getInt('dictionaryUpdatePeriod') ??
          1];

  @override
  set dictionaryUpdatePeriod(DictionaryUpdatePeriod dup) =>
      _prefs.setInt('dictionaryUpdatePeriod', dup.index);

  @override
  bool get isFirstLaunch {
    final ifFirst = _prefs.getBool('firstLaunch') ?? true;
    if (ifFirst) _prefs.setBool('firstLaunch', false);
    return ifFirst;
  }

  @override
  String get lastNativeLogin => _prefs.getString('lastNativeLogin') ?? '';

  @override
  set lastNativeLogin(String newLogin) {
    _prefs.setString('lastNativeLogin', newLogin);
  }

  @override
  bool get signedOut => _prefs.getBool('signedOut') ?? false;

  @override
  set signedOut(bool value) => _prefs.setBool('signedOut', value);

  @override
  List<String> get hotseatNames => _prefs.getStringList('hotseatNames') ?? [];

  @override
  set hotseatNames(List<String> names) =>
      _prefs.setStringList('hotseatNames', names);

  @override
  List<int> get recentCountries => [
    for (final code in _prefs.getStringList('recentCountries') ?? const [])
      ?int.tryParse(code),
  ].take(maxRecentCountries).toList();

  @override
  set recentCountries(List<int> codes) => _prefs.setStringList(
    'recentCountries',
    [for (final code in codes.take(maxRecentCountries)) '$code'],
  );

  @override
  Map<String, int> get achievementsProgress {
    final stored = _prefs.getString('achievementsProgress');
    if (stored == null) return {};

    try {
      return Map<String, int>.from(jsonDecode(stored) as Map);
    } on Object {
      return {};
    }
  }

  @override
  set achievementsProgress(Map<String, int> progress) =>
      _prefs.setString('achievementsProgress', jsonEncode(progress));

  @override
  AppThemeMode get themeMode => AppThemeMode.values.firstWhere(
    (mode) => mode.name == _prefs.getString('themeMode'),
    orElse: () => AppThemeMode.system,
  );

  @override
  set themeMode(AppThemeMode mode) => _prefs.setString('themeMode', mode.name);
}
