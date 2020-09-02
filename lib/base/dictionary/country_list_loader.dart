import 'package:lets_play_cities/base/dictionary/country_entity.dart';

/// An interface that provides functions for country list loading
abstract class CountryListLoaderService {
  /// Loads country list from storage.
  Future<List<CountryEntity>> loadCountryList();
}
