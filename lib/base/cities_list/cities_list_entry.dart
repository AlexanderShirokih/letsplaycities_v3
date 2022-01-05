import 'package:equatable/equatable.dart';

/// Simple data class for wrapping city name and it's countryCode
class CitiesListEntry extends Equatable {
  final String cityName;
  final int countryCode;

  const CitiesListEntry(this.cityName, this.countryCode);

  @override
  List<Object?> get props => [cityName, countryCode];
}
