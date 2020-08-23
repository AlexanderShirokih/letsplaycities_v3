/// The result of checking a word in the database
enum CityResult {
  OK,
  CITY_NOT_FOUND,
  ALREADY_USED,
}

/// Game difficulty values
enum Difficulty { EASY, MEDIUM, HARD }

class CityProperties {
  //TODO:  (var diff: Byte, var countryCode: Short)

  resetUsageFlag() {
    //TODO: if (diff < 0) diff = (-diff).toByte()
  }

  bool isNotUsed() => true; //TODO: diff > 0

  markUsed() {
    //  TODO:  if (diff > 0) diff = (-diff).toByte()
  }
}

/// Interface that provides functions for access to dictionary database.
class DictionaryService {
  /// Current dictionary difficulty. Used for getting random city.
  /// Returns current difficulty
  Difficulty get difficulty => Difficulty.EASY;

  /// Checks [city] in dictionary database.
  /// Returns a [Future] with [CityResult.OK] if city not used before, [CityResult.ALREADY_USED] if
  /// city has already been used, [CityResult.CITY_NOT_FOUND] if city not found in dictionary.
  Future<CityResult> checkCity(String city) => Future.value(CityResult.OK);

  /// Returns random word from database starting at [firstChar].
  /// Returns a [Future] with a random city or an empty string if there are no available words
  /// starting at [firstChar]
  Future<String> getRandomWord(String firstChar) => Future.value("Заглушка");

  /// Returns country code for [city] or `0` if country code for the [city] is not found.
  int getCountryCode(String city) => 0;

  /// Returns correction variants for [city] or empty list if there are no corrections available.
  Future<List<String>> getCorrectionVariants(String city) => Future.value([]);

  /// Returns all cities in database.
  Map<String, CityProperties> getAll() => {};

  /// Marks [city] as already used
  markUsed(String city) {}

  /// Used to clean up all resources used by dictionary.
  clear() {}

  /// Used to reset usage flags and other data to it's default state
  reset() {}
}
