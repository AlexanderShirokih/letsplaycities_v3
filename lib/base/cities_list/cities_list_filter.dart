import 'package:equatable/equatable.dart';

import 'package:lets_play_cities/base/cities_list/cities_list_entry.dart';

/// A class that can filter elements of cities list
class CitiesListFilter extends Equatable {
  static final RegExp _nameSplitPattern = RegExp('[ -]');

  final String nameFilter;
  final CountryListFilter countryFilter;

  CitiesListFilter({
    this.nameFilter = '',
    CountryListFilter? countryFilter,
  }) : countryFilter = countryFilter ?? CountryListFilter.empty();

  /// Creates copy of this filter with customizable params
  /// `null` value for input argument means value is not changed
  CitiesListFilter copy(
          {String? nameFilter, CountryListFilter? countryFilter}) =>
      CitiesListFilter(
        nameFilter: nameFilter ?? this.nameFilter,
        countryFilter: countryFilter ?? this.countryFilter,
      );

  /// Returns `true` if filter doesn't filter anything
  bool get isEmpty => nameFilter.isEmpty && countryFilter.isAllPresent;

  /// Returns list containing elements that passes the filter
  List<CitiesListEntry> filter(List<CitiesListEntry> original) => original
      .where(
        (entry) =>
            (countryFilter.isAllPresent || countryFilter.matches(entry)) &&
            _matches(entry.cityName),
      )
      .toList();

  bool _matches(String cityName) =>
      nameFilter.isEmpty ||
      cityName.startsWith(nameFilter) ||
      cityName
          .split(_nameSplitPattern)
          .any((part) => part.startsWith(nameFilter));

  /// Returns `true` if this filter is a sub filter of [prev]
  /// (is more concrete than previous)
  bool isDetailing(CitiesListFilter prev) =>
      this == prev ||
      nameFilter.startsWith(prev.nameFilter) &&
          countryFilter.isDetailing(prev.countryFilter);

  @override
  List<Object> get props => [nameFilter, countryFilter];

  @override
  bool get stringify => true;
}

/// Wrapper class for a list of allowed countries.
/// If all countries in list is present [isAllPresent] should be `true`.
class CountryListFilter extends Equatable {
  final List<int> allowedCountryCodes;
  final bool isAllPresent;

  const CountryListFilter(this.allowedCountryCodes, this.isAllPresent);

  factory CountryListFilter.empty() => CountryListFilter(<int>[], true);

  /// Returns `true` if [city] passes the filter.
  bool matches(CitiesListEntry city) =>
      isAllPresent ||
      allowedCountryCodes.any((allowed) => allowed == city.countryCode);

  /// Returns `true` if this filter is a sub filter of [prev] (is more concrete than previous)
  bool isDetailing(CountryListFilter prev) {
    if (this == prev || prev.isAllPresent) return true;
    if (prev.allowedCountryCodes.length < allowedCountryCodes.length) {
      return false;
    }

    return allowedCountryCodes
        .every((element) => prev.allowedCountryCodes.contains(element));
  }

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [isAllPresent, allowedCountryCodes];
}
