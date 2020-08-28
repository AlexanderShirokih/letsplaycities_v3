import 'package:lets_play_cities/base/dictionary.dart';

import '../preferences.dart';

/// Proxy object for [DictionaryService] that controls access depending of game
/// preferences.
class DictionaryProxy {
  final DictionaryService _dictionaryService;
  final GamePreferences _prefs;

  DictionaryProxy(this._dictionaryService, this._prefs);

  /// Returns index of current difficulty level
  int get difficultyIndex => _dictionaryService.difficulty.index;

  /// Returns a random word from the database starting at [firstChar] or empty string if no words left
  /// starting at the [firstChar].
  Future<String> getRandomWord(String firstChar) =>
      _dictionaryService.getRandomWord(firstChar);

  /// Checks [city] in dictionary database.
  /// Returns [CityResult.OK] if city not used before, [CityResult.ALREADY_USED] if
  /// [city] has already been used, [CityResult.CITY_NOT_FOUND] if [city] not found in dictionary.
  Future<CityResult> checkCity(String city) =>
      _dictionaryService.checkCity(city);

  /// Returns correction variants for [city] or empty list if there are no corrections available
  /// or corrections is disabled in preferences.
  Future<List<String>> getCorrectionVariants(String city) =>
      (_prefs.isCorrectionEnabled())
          ? _dictionaryService.getCorrectionVariants(city)
          : Future.value([]);

  /// Returns the country code for the [city] or `0` code for the [city] wasn't found.
  int getCountryCode(String city) => _dictionaryService.getCountryCode(city);
}