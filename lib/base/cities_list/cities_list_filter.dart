import 'package:lets_play_cities/base/cities_list/cities_list_entry.dart';

/// A class that can filter elements of cities list
class CitiesListFilter {
  static final RegExp _nameSplitPattern = RegExp("[ -]");

  final String nameFilter;
  final CountryListFilter countryFilter;

  const CitiesListFilter({
    this.nameFilter = "",
    this.countryFilter = const CountryListFilter.empty(),
  })  : assert(nameFilter != null),
        assert(countryFilter != null);

  /// Replaces this filter parameters with [other] parameters if [other]'s
  /// params is not empty and returns new filter as result
  CitiesListFilter mergeWith(CitiesListFilter other) => CitiesListFilter(
        nameFilter:
            other.nameFilter.isEmpty ? this.nameFilter : other.nameFilter,
        countryFilter: other.countryFilter.isAllPresent
            ? this.countryFilter
            : other.countryFilter,
      );

  /// Returns `true` if filter doesn't filter anything
  bool get isEmpty => nameFilter.isEmpty && countryFilter.isAllPresent;

  /// Returns list containing elements that passes the filter
  List<CitiesListEntry> filter(List<CitiesListEntry> original) => original
      .where(
        (entry) => countryFilter.matches(entry) && _matches(entry.cityName),
      )
      .toList();

  bool _matches(String cityName) => (nameFilter.isEmpty ||
      cityName.startsWith(nameFilter) ||
      cityName
          .split(_nameSplitPattern)
          .any((part) => part.startsWith(nameFilter)));

  /// Returns `true` if this filter is a sub filter of [prev] (is more concrete than previous)
  bool isDetailing(CitiesListFilter prev) =>
      this == prev ||
      (nameFilter.startsWith(prev.nameFilter) &&
          countryFilter.isDetailing(prev.countryFilter));
}

/// Wrapper class for a list of allowed countries.
/// If all countries in list is present [isAllPresent] should be `true`.
class CountryListFilter {
  final List<int> allowedCountryCodes;
  final bool isAllPresent;

  const CountryListFilter(this.allowedCountryCodes, this.isAllPresent);

  const CountryListFilter.empty() : this(null, true);

  /// Returns `true` if [city] passes the filter.
  bool matches(CitiesListEntry city) =>
      isAllPresent ||
      allowedCountryCodes.any((allowed) => allowed == city.countryCode);

  /// Returns `true` if this filter is a sub filter of [prev] (is more concrete than previous)
  bool isDetailing(CountryListFilter prev) {
    if (this == prev || prev.isAllPresent) return true;
    if (prev.allowedCountryCodes.length < allowedCountryCodes.length)
      return false;

    return allowedCountryCodes
        .every((element) => prev.allowedCountryCodes.contains(element));
  }
}
