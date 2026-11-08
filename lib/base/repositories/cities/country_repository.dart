import 'package:lets_play_cities/base/dictionary/country_entity.dart';
import 'package:lets_play_cities/base/dictionary/impl/country_list_loader_factory.dart';

/// Repository that manages country list
class CountryRepository {
  final CountryListLoaderServiceFactory _countryListLoaderServiceFactory;

  /// Name of the country that a code missing from the list stands for.
  final String _unknownCountryName;

  List<CountryEntity>? _cache;

  CountryRepository(
    this._countryListLoaderServiceFactory,
    this._unknownCountryName,
  );

  /// Gets a list of all countries
  Future<List<CountryEntity>> getCountryList() async {
    final currentCache = _cache;

    if (currentCache == null) {
      final countryListService = _countryListLoaderServiceFactory
          .createCountryList();

      final countries = await countryListService.loadCountryList();
      _cache = countries;
      return countries;
    } else {
      return currentCache;
    }
  }

  /// Gets country entity by country code.
  /// A code missing from the list (a newer dictionary or the server may use
  /// one) gives the unknown country with code 0, which has a flag image.
  Future<CountryEntity> getCountryById(int country) async {
    final countries = await getCountryList();

    return countries.firstWhere(
      (element) => element.countryCode == country,
      orElse: () => CountryEntity(_unknownCountryName, 0, false),
    );
  }
}
