import 'package:lets_play_cities/base/dictionary/country_entity.dart';
import 'package:lets_play_cities/base/dictionary/impl/country_list_loader_factory.dart';

/// Repository that manages country list
class CountryRepository {
  final CountryListLoaderServiceFactory _countryListLoaderServiceFactory;

  List<CountryEntity>? _cache;

  CountryRepository(this._countryListLoaderServiceFactory);

  /// Gets a list of all countries
  Future<List<CountryEntity>> getCountryList() async {
    final currentCache = _cache;

    if (currentCache == null) {
      final countryListService =
          _countryListLoaderServiceFactory.createCountryList();

      final countries = await countryListService.loadCountryList();
      _cache = countries;
      return countries;
    } else {
      return currentCache;
    }
  }

  /// Gets country entity by country code
  Future<CountryEntity> getCountryById(int country) async {
    final countries = await getCountryList();

    return countries.firstWhere((element) => element.countryCode == country);
  }
}
