import 'package:lets_play_cities/base/dictionary/country_entity.dart';
import 'package:lets_play_cities/base/dictionary/country_list_loader.dart';
import 'package:lets_play_cities/base/dictionary/impl/country_list_loader_factory.dart';

/// Country list loader whose list comes from [load].
class FakeCountryLoaderFactory
    implements CountryListLoaderServiceFactory, CountryListLoaderService {
  final Future<List<CountryEntity>> Function() load;

  FakeCountryLoaderFactory(this.load);

  @override
  CountryListLoaderService createCountryList() => this;

  @override
  Future<List<CountryEntity>> loadCountryList() => load();
}
