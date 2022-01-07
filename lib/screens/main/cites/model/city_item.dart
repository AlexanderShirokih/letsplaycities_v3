import 'package:equatable/equatable.dart';
import 'package:lets_play_cities/base/dictionary/country_entity.dart';

/// Model, that describes a city with its country
class CityItem extends Equatable {
  /// City name in the title case
  final String cityName;

  /// Country that owns the city
  final CountryEntity country;

  const CityItem(this.cityName, this.country);

  @override
  List<Object?> get props => [cityName, country];
}
