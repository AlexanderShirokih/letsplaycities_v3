import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:lets_play_cities/base/cities_list/cities_list_entry.dart';
import 'package:lets_play_cities/base/cities_list/cities_list_filter.dart';
import 'package:lets_play_cities/base/dictionary/country_entity.dart';
import 'package:lets_play_cities/base/dictionary/impl/country_list_loader_factory.dart';
import 'package:lets_play_cities/base/dictionary/impl/dictionary_factory.dart';
import 'package:meta/meta.dart';

part 'cities_list_event.dart';
part 'cities_list_state.dart';

/// BLoC for managing cities list
class CitiesListBloc extends Bloc<CitiesListEvent, CitiesListState> {
  CitiesListBloc() : super(CitiesListInitial()) {
    add(CitiesListBeginDataLoadingEvent());
  }

  @override
  Stream<CitiesListState> mapEventToState(
    CitiesListEvent event,
  ) async* {
    if (event is CitiesListBeginDataLoadingEvent) {
      yield* _loadData();
    } else if (event is CitiesListUpdateNameFilter) {
      yield* _filterData(nameFilter: event.nameFilter);
    } else if (event is CitiesListUpdateCountryFilterEvent) {
      yield* _filterData(countryFilter: event.countryFilter);
    }
  }

  Stream<CitiesListDataState> _loadData() async* {
    final citiesList = DictionaryFactory().createDictionary().then(
        (dictionary) => dictionary
            .getAll()
            .entries
            .map((e) => CitiesListEntry(e.key, e.value.countryCode))
            .toList(growable: false)
              ..sort((a, b) => a.cityName.compareTo(b.cityName)));

    final countryList =
        CountryListLoaderServiceFactory().createCountryList().loadCountryList();

    // Show data
    yield CitiesListAllDataState(await citiesList, await countryList);
  }

  Stream<CitiesListDataState> _filterData({
    String? nameFilter,
    CountryListFilter? countryFilter,
  }) async* {
    if (!(state is CitiesListDataState)) return;

    // Update existing filter or create new
    final filter = state is CitiesListFilteredDataState
        ? (state as CitiesListFilteredDataState)
            .filter
            .copy(nameFilter: nameFilter, countryFilter: countryFilter)
        : CitiesListFilter(
            nameFilter: nameFilter ?? '', countryFilter: countryFilter);

    // Keep all-data state
    final original = state is CitiesListFilteredDataState
        ? (state as CitiesListFilteredDataState).originalState
        : state as CitiesListAllDataState;

    // Short-circuit for empty filters
    if (filter.isEmpty) {
      yield original;
      return;
    }

    // If current filter is more concrete then previous - filter from previous
    final candidate = state is CitiesListFilteredDataState &&
            filter.isDetailing((state as CitiesListFilteredDataState).filter)
        ? (state as CitiesListFilteredDataState).citiesList
        : original.citiesList;

    final filtered = filter.filter(candidate);

    yield CitiesListFilteredDataState(original, filtered, filter);
  }
}
