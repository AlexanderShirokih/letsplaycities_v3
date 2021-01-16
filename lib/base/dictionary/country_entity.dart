/// Data class describing country.
class CountryEntity {
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
}
