import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/base/cities_list/bloc/cities_list_bloc.dart';
import 'package:lets_play_cities/base/cities_list/cities_list_entry.dart';
import 'package:lets_play_cities/base/cities_list/cities_list_filter.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/common/common_widgets.dart';
import 'package:lets_play_cities/screens/common/search_app_bar.dart';
import 'package:lets_play_cities/screens/common/utils.dart';
import 'package:lets_play_cities/screens/main/cites/list/country_filter_dialog.dart';
import 'package:lets_play_cities/screens/main/cites/model/city_edit_action.dart';
import 'package:lets_play_cities/screens/main/cites/requests/city_edit_actions_screen.dart';
import 'package:lets_play_cities/screens/main/cites/requests/city_requests_list_screen.dart';

import 'widgets/city_list_item.dart';

/// Screen that shows a list of all database cities
class CitiesListScreen extends StatelessWidget {
  const CitiesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return BlocProvider(
      create: (_) => CitiesListBloc(GetIt.instance.get(), GetIt.instance.get()),
      child: BlocBuilder<CitiesListBloc, CitiesListState>(
        builder: (ctx, state) => Scaffold(
          floatingActionButton: FloatingActionButton(
            child: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      CityEditActionsScreen(action: CityEditAction.add),
                ),
              );
            },
          ),
          appBar: SearchAppBar(
            title: t.citiesList.title,
            searchHint: t.citiesList.enterCity,
            actions: [_createFilterButton(ctx)],
            onSearchTextChanged: (text) => ctx.read<CitiesListBloc>().add(
              CitiesListUpdateNameFilter(text.toLowerCase()),
            ),
          ),
          body: _buildBody(t, state),
        ),
      ),
    );
  }

  Widget _buildBody(Translations t, CitiesListState state) {
    if (state is CitiesListInitial) {
      return LoadingView(t.citiesList.loading);
    } else if (state is CitiesListDataState) {
      return _CitiesListContent(data: state);
    } else {
      throw ('Unexpected state $state');
    }
  }

  Widget _createFilterButton(BuildContext context) {
    final bloc = context.watch<CitiesListBloc>();
    return IconButton(
      icon: Icon(Icons.filter_list),
      onPressed: () {
        if (bloc.state is! CitiesListDataState) return;
        final dataState = bloc.state as CitiesListDataState;

        showDialog<CountryListFilter>(
          context: context,
          builder: (_) => CountryFilterDialog(
            dataState.countryList,
            (dataState is CitiesListFilteredDataState)
                ? (dataState.filter.countryFilter.isAllPresent
                      ? null
                      : dataState.filter.countryFilter.allowedCountryCodes)
                : null,
          ),
        ).then((countryFilter) {
          if (countryFilter != null) {
            bloc.add(CitiesListUpdateCountryFilterEvent(countryFilter));
          }
        });
      },
    );
  }
}

class _CitiesListContent extends StatefulWidget {
  final CitiesListDataState data;

  const _CitiesListContent({required this.data});

  @override
  _CitiesListContentState createState() => _CitiesListContentState();
}

class _CitiesListContentState extends State<_CitiesListContent> {
  /// The expanded city. It is kept by value rather than by list position
  /// because filtering replaces the list while this state survives.
  CitiesListEntry? _activeEntry;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final data = widget.data;

    return ListView.builder(
      itemCount: data.citiesList.length + 1,
      itemBuilder: (context, index) => index == 0
          ? Padding(
              padding: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 0.0),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CityRequestsListScreen(),
                        ),
                      ),
                      child: Text(t.citiesList.about),
                    ),
                  ),
                  Divider(thickness: 2.0),
                ],
              ),
            )
          : withData(
              data.citiesList[index - 1],
              (CitiesListEntry entry) => _createListTile(
                data: data,
                missingCountryText: t.citiesList.unkCity,
                expanded: entry == _activeEntry,
                entry: entry,
                onTap: () => setState(() {
                  _activeEntry = entry == _activeEntry ? null : entry;
                }),
              ),
            ),
    );
  }

  Widget _createListTile({
    required String missingCountryText,
    required CitiesListDataState data,
    required CitiesListEntry entry,
    required bool expanded,
    required void Function() onTap,
  }) {
    final cityItem = data.getCityItem(entry, missingCountryText);

    return CityListItem(
      key: ObjectKey(entry),
      onTap: onTap,
      cityItem: cityItem,
      expanded: expanded,
      onEdit: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CityEditActionsScreen(
            action: CityEditAction.edit,
            city: cityItem.cityName,
          ),
        ),
      ),
      onRemove: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CityEditActionsScreen(
            action: CityEditAction.remove,
            city: cityItem.cityName,
          ),
        ),
      ),
    );
  }
}
