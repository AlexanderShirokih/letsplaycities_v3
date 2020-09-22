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

/// Event emitted when user wants to filter cities list
class CitiesListFilteringEvent extends CitiesListEvent {
  final String nameFilter;
  final CountryListFilter countryFilter;

  const CitiesListFilteringEvent({this.nameFilter, this.countryFilter});

  @override
  List<Object> get props => [nameFilter, countryFilter];
}
