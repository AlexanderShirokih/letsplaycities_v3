part of 'cities_list_bloc.dart';

/// BLoC's events for cities list
abstract class CitiesListEvent extends Equatable {
  const CitiesListEvent();
}

/// Event that initiate data loading
class CitiesListBeginDataLoadingEvent extends CitiesListEvent {
  @override
  List<Object> get props => [];

  const CitiesListBeginDataLoadingEvent();
}

class CitiesListUpdateNameFilter extends CitiesListEvent {
  final String nameFilter;

  const CitiesListUpdateNameFilter(this.nameFilter);

  @override
  List<Object> get props => [nameFilter];
}

/// Event emitted when user wants to filter cities list
class CitiesListUpdateCountryFilterEvent extends CitiesListEvent {
  final CountryListFilter countryFilter;

  const CitiesListUpdateCountryFilterEvent(this.countryFilter);

  @override
  List<Object> get props => [countryFilter];
}
