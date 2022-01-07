import 'package:lets_play_cities/base/dictionary/country_entity.dart';
import 'package:lets_play_cities/base/dictionary/impl/country_list_loader_factory.dart';

/// Repository that manages country list
class CountryRepository {
  final CountryListLoaderServiceFactory _countryListLoaderServiceFactory;

  const CountryRepository(this._countryListLoaderServiceFactory);

  /// Gets a list of all countries
  Future<List<CountryEntity>> getCountryList() {
    final countryListService =
        _countryListLoaderServiceFactory.createCountryList();

    return countryListService.loadCountryList();
  }
}
