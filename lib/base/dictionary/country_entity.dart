import 'package:equatable/equatable.dart';

/// Data class describing country.
class CountryEntity extends Equatable {
  /// Country name
  final String name;

  /// Flag code for country
  final int countryCode;

  /// `true` if there is a city(capital) with the same name as country
  final bool hasSiblingCity;

  const CountryEntity(
    this.name,
    this.countryCode,
    this.hasSiblingCity,
  );

  @override
  List<Object?> get props => [name, countryCode, hasSiblingCity];
}
