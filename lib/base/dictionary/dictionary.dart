import 'city_properties.dart';

/// The result of checking a word in the database
enum CityResult {
  OK,
  CITY_NOT_FOUND,
  ALREADY_USED,
}

enum Difficulty { EASY, MEDIUM, HARD }

/// Interface that provides functions for access to dictionary database.
abstract class DictionaryService {
  /// Checks [city] in the dictionary database.
  /// Returns a [Future] with [CityResult.OK] if city not used before, [CityResult.ALREADY_USED] if
  /// city has already been used, [CityResult.CITY_NOT_FOUND] if city not found in dictionary.
  Future<CityResult> checkCity(String city);

  /// Returns random word from database starting at [firstChar].
  /// Returns a [Future] with a random city or an empty string if there are no words left
  /// starting at the [firstChar] and [difficulty].
  Future<String> getRandomWordByDifficulty(
      String firstChar, Difficulty difficulty);

  /// Returns country code for [city] or `0` if country code for the [city] is not found.
  int getCountryCode(String city);

  /// Returns correction variants for [city] or empty list if there are no corrections available.
  Future<Set<String>> getCorrectionVariants(String city);

  /// Returns all cities in database.
  Map<String, CityProperties> getAll();

  /// Marks [city] as already used. If city doesn't exists does nothing.
  void markUsed(String city);

  /// Used to clean up all resources used by dictionary.
  void clear();

  /// Used to reset usage flags and other data to it's default state
  void reset();
}
