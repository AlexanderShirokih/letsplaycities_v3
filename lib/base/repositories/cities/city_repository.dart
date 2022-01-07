import 'package:lets_play_cities/base/cities_list/cities_list_entry.dart';
import 'package:lets_play_cities/base/dictionary.dart';
import 'package:lets_play_cities/base/dictionary/impl/dictionary_factory.dart';

/// Repository used to manage city list
class CityRepository {
  final DictionaryFactory _dictionaryFactory;

  const CityRepository(this._dictionaryFactory);

  /// Gets all cities from the current game dictionary
  Future<List<CitiesListEntry>> getCityList() async {
    final dictionaryService = await _dictionaryFactory.createDictionary();

    return dictionaryService
        .getAll()
        .entries
        .map((e) => CitiesListEntry(e.key, e.value.countryCode))
        .toList(growable: false);
  }

  /// Returns information about the city by its name
  Future<CitiesListEntry?> getCityByName(String city) async {
    final dictionaryService = await _dictionaryFactory.createDictionary();

    final result = await dictionaryService.checkCity(city);
    if (result == CityResult.CITY_NOT_FOUND) {
      return null;
    }

    final countryCode = dictionaryService.getCountryCode(city);

    return CitiesListEntry(
      city,
      countryCode,
    );
  }
}
