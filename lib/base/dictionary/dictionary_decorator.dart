import 'package:lets_play_cities/base/dictionary.dart';

import '../preferences.dart';

/// Proxy object for [DictionaryService] that controls access depending of game
/// preferences.
class DictionaryDecorator extends DictionaryService {
  final DictionaryService _dictionaryService;
  final GamePreferences _prefs;

  DictionaryDecorator(this._dictionaryService, this._prefs);

  /// Returns index of current difficulty level
  Difficulty get difficulty => _prefs.wordsDifficulty;

  /// Returns a random word from the database starting at [firstChar] or an empty string if there are no words left
  /// starting at the [firstChar].
  Future<String> getRandomWord(String firstChar) =>
      _dictionaryService.getRandomWordByDifficulty(firstChar, difficulty);

  /// Returns correction variants for [city] or empty list if there are no corrections available
  /// or corrections is disabled in preferences.
  @override
  Future<Set<String>> getCorrectionVariants(String city) =>
      (_prefs.correctionEnabled)
          ? _dictionaryService.getCorrectionVariants(city)
          : Future.value({});

  @override
  Future<CityResult> checkCity(String city) =>
      _dictionaryService.checkCity(city);

  @override
  void clear() => _dictionaryService.clear();

  @override
  Map<String, CityProperties> getAll() => _dictionaryService.getAll();

  @override
  int getCountryCode(String city) => _dictionaryService.getCountryCode(city);

  @override
  Future<String> getRandomWordByDifficulty(
          String firstChar, Difficulty difficulty) =>
      _dictionaryService.getRandomWordByDifficulty(firstChar, difficulty);

  @override
  void markUsed(String city) => _dictionaryService.markUsed(city);

  @override
  void reset() => _dictionaryService.reset();
}
