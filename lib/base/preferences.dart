import 'dart:convert';

import 'package:lets_play_cities/base/dictionary.dart';
import 'package:lets_play_cities/base/scoring.dart';
import 'package:lets_play_cities/remote/account.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Represents application preferences
abstract class GamePreferences {
  /// Words difficulty level.
  Difficulty get wordsDifficulty;

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
  /// [DictionaryUpdatePeriod.NEVER] means don't fetch updates.
  DictionaryUpdatePeriod get dictionaryUpdatePeriod;

  set dictionaryUpdatePeriod(DictionaryUpdatePeriod dup);

  /// Is there a first application launch?
  /// After first calls sets to false
  bool get isFirstLaunch;

  /// Gets currently logged in user credentials
  Credential get currentCredentials;

  /// Updates current credentials. Pass `null` to log out user.
  Future setCurrentCredentials(Credential newCredentials);

  String get lastNativeLogin;

  set lastNativeLogin(String newLogin);
}

class SharedPreferencesGamePrefs extends GamePreferences {
  final SharedPreferences _prefs;

  SharedPreferencesGamePrefs(this._prefs);

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
      : utf8.decode(base64.decode(_prefs.getString('scoringData')));

  @override
  set scoringData(String s) =>
      _prefs.setString('scoringData', base64.encode(utf8.encode(s)));

  @override
  DateTime get lastDictionaryCheckDate => DateTime.fromMillisecondsSinceEpoch(
      _prefs.getInt('lastDictionaryCheckDate') ?? 0);

  @override
  set lastDictionaryCheckDate(DateTime d) =>
      _prefs.setInt('lastDictionaryCheckDate', d.millisecondsSinceEpoch);

  @override
  DictionaryUpdatePeriod get dictionaryUpdatePeriod => DictionaryUpdatePeriod
      .values[_prefs.getInt('dictionaryUpdatePeriod') ?? 1];

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
  Future setCurrentCredentials(Credential newCredentials) {
    return newCredentials == null
        ? _prefs.remove('uhash').then((_) => _prefs.remove('uid'))
        : _prefs
            .setString('uhash', newCredentials.accessToken)
            .then((_) => _prefs.setInt('uid', newCredentials.userId));
  }

  @override
  Credential get currentCredentials {
    final userId = _prefs.getInt('uid');
    final uhash = _prefs.getString('uhash');

    if (userId == null || uhash == null || userId == 0) {
      return null;
    }

    return Credential(userId: userId, accessToken: uhash);
  }

  // TODO: Implement migration
  @override
  String get lastNativeLogin => _prefs.getString('lastNativeLogin');

  @override
  set lastNativeLogin(String newLogin) {
    _prefs.setString('lastNativeLogin', newLogin);
  }
}
