part of 'cities_list_bloc.dart';

abstract class CitiesListState extends Equatable {
  const CitiesListState();
}

/// Initial state of cities list screen
class CitiesListInitial extends CitiesListState {
  @override
  List<Object> get props => [];
}

/// Base state for showing data
@sealed
abstract class CitiesListDataState extends CitiesListState {
  /// List containing available cites
  List<CitiesListEntry> get citiesList;

  /// List containing all counties
  List<CountryEntity> get countryList;

  const CitiesListDataState();

  CityItem getCityItem(CitiesListEntry entry, String missingCountryText) {
    final countryEntity = countryList.firstWhere(
      (county) => county.countryCode == entry.countryCode,
      orElse: () => CountryEntity(missingCountryText, 0, false),
    );

    return CityItem(
      entry.cityName.toTitleCase(),
      countryEntity,
    );
  }
}

/// State for showing all data (without any filters)
class CitiesListAllDataState extends CitiesListDataState {
  /// List containing all cites
  final List<CitiesListEntry> _citiesList;

  /// List containing all counties
  final List<CountryEntity> _countryList;

  /// Creates data state with loaded data
  const CitiesListAllDataState(this._citiesList, this._countryList);

  @override
  List<Object> get props => [_citiesList, _countryList];

  @override
  List<CitiesListEntry> get citiesList => _citiesList;

  @override
  List<CountryEntity> get countryList => _countryList;
}

/// State for showing filtered data
class CitiesListFilteredDataState extends CitiesListDataState {
  /// State containing all available data
  final CitiesListAllDataState originalState;

  /// List containing only filtered cites
  final List<CitiesListEntry> _filteredCities;

  /// Associated filter instance
  final CitiesListFilter filter;

  /// Creates data state with original data and filter
  const CitiesListFilteredDataState(
      this.originalState, this._filteredCities, this.filter);

  @override
  List<Object> get props => [originalState, _filteredCities];

  @override
  List<CitiesListEntry> get citiesList => _filteredCities;

  @override
  List<CountryEntity> get countryList => originalState.countryList;
}
