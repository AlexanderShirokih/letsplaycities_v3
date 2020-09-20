import 'package:lets_play_cities/base/cities_list/cities_list_entry.dart';

/// A class that can filter elements of cities list
class CitiesListFilter {
  final String nameFilter;

  const CitiesListFilter(this.nameFilter);

  /// Returns `true` if filter doesn't filter anything
  bool get isEmpty => nameFilter.isEmpty;

  /// Returns list containing elements that passes the filter
  List<CitiesListEntry> filter(List<CitiesListEntry> original) =>
      original.where((entry) => entry.cityName.startsWith(nameFilter)).toList();

  /// Returns `true` if this filter is a sub filter of [prev] (is more concrete than previous)
  bool isDetailing(CitiesListFilter prev) {
    return nameFilter.startsWith(prev.nameFilter);
  }
}
