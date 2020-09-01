import 'package:lets_play_cities/base/dictionary.dart';

import '../preferences.dart';

/// Proxy object for [DictionaryService] that controls access depending of game
/// preferences.
class DictionaryProxy {
  final DictionaryService _dictionaryService;
  final GamePreferences _prefs;

  DictionaryProxy(this._dictionaryService, this._prefs)
      : assert(_dictionaryService != null),
        assert(_prefs != null);

  /// Returns index of current difficulty level
  int get difficultyIndex => _prefs.wordsDifficulty;

  /// Returns a random word from the database starting at [firstChar] or an empty string if there are no words left
  /// starting at the [firstChar] and [difficulty].
  Future<String> getRandomWord(String firstChar, int difficulty) =>
      _dictionaryService.getRandomWord(firstChar, difficultyIndex);

  /// Checks [city] in dictionary database.
  /// Returns [CityResult.OK] if city not used before, [CityResult.ALREADY_USED] if
  /// [city] has already been used, [CityResult.CITY_NOT_FOUND] if [city] not found in dictionary.
  Future<CityResult> checkCity(String city) =>
      _dictionaryService.checkCity(city);

  /// Returns correction variants for [city] or empty list if there are no corrections available
  /// or corrections is disabled in preferences.
  Future<Set<String>> getCorrectionVariants(String city) =>
      (_prefs.isCorrectionEnabled())
          ? _dictionaryService.getCorrectionVariants(city)
          : Future.value({});

  /// Returns the country code for the [city] or `0` code for the [city] wasn't found.
  int getCountryCode(String city) => _dictionaryService.getCountryCode(city);
}
