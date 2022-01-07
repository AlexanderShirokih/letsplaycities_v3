import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/base/cities_list/bloc/cities_list_bloc.dart';
import 'package:lets_play_cities/base/cities_list/cities_list_entry.dart';
import 'package:lets_play_cities/base/cities_list/cities_list_filter.dart';
import 'package:lets_play_cities/l18n/localization_service.dart';
import 'package:lets_play_cities/screens/common/common_widgets.dart';
import 'package:lets_play_cities/screens/common/search_app_bar.dart';
import 'package:lets_play_cities/screens/common/utils.dart';
import 'package:lets_play_cities/screens/main/cites/list/country_filter_dialog.dart';
import 'package:lets_play_cities/screens/main/cites/model/city_edit_action.dart';
import 'package:lets_play_cities/screens/main/cites/requests/city_edit_actions_screen.dart';

import 'widgets/city_list_item.dart';

/// Screen that shows a list of all database cities
class CitiesListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) => buildWithLocalization(
        context,
        (l10n) => BlocProvider(
          create: (_) => CitiesListBloc(
            GetIt.instance.get(),
            GetIt.instance.get(),
          ),
          child: BlocBuilder<CitiesListBloc, CitiesListState>(
            builder: (ctx, state) => Scaffold(
              floatingActionButton: FloatingActionButton(
                child: Icon(Icons.add),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CityEditActionsScreen(
                        action: CityEditAction.Add,
                      ),
                    ),
                  );
                },
              ),
              appBar: SearchAppBar(
                title: l10n.citiesList['title'],
                searchHint: l10n.citiesList['enter_city'],
                actions: [_createFilterButton(ctx)],
                onSearchTextChanged: (text) => ctx.read<CitiesListBloc>().add(
                      CitiesListUpdateNameFilter(text.toLowerCase()),
                    ),
              ),
              body: _buildBody(l10n, state),
            ),
          ),
        ),
      );

  Widget _buildBody(LocalizationService l10n, CitiesListState state) {
    if (state is CitiesListInitial) {
      return LoadingView(l10n.citiesList['loading'].toString());
    } else if (state is CitiesListDataState) {
      return _CitiesListContent(l10n: l10n, data: state);
    } else {
      throw ('Unexpected state $state');
    }
  }

  Widget _createFilterButton(BuildContext context) {
    final bloc = context.watch<CitiesListBloc>();
    return IconButton(
      icon: Icon(Icons.filter_list),
      onPressed: () {
        if (!(bloc.state is CitiesListDataState)) return;
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
            bloc.add(
              CitiesListUpdateCountryFilterEvent(countryFilter),
            );
          }
        });
      },
    );
  }
}

class _CitiesListContent extends StatefulWidget {
  final LocalizationService l10n;
  final CitiesListDataState data;

  const _CitiesListContent({
    Key? key,
    required this.l10n,
    required this.data,
  }) : super(key: key);

  @override
  _CitiesListContentState createState() => _CitiesListContentState();
}

class _CitiesListContentState extends State<_CitiesListContent> {
  int _active = -1;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    return ListView.builder(
      itemCount: data.citiesList.length + 1,
      itemBuilder: (context, index) => index == 0
          ? Padding(
              padding: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 0.0),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      // TODO: REMOVE
                      onPressed: () {
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(
                        //     builder: (_) => CitiesListAboutScreen(),
                        //   ),
                        // );
                      },
                      child: Text(widget.l10n.citiesList['about']),
                    ),
                  ),
                  Divider(thickness: 2.0),
                ],
              ),
            )
          : _createListTile(
              data: data,
              missingCountryText: widget.l10n.citiesList['unk_city'],
              expanded: index == _active,
              entry: data.citiesList[index - 1],
              onTap: () => setState(() {
                final alreadyActive = index == _active;
                _active = alreadyActive ? -1 : index;
              }),
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
            action: CityEditAction.Edit,
            city: cityItem.cityName,
          ),
        ),
      ),
      onRemove: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CityEditActionsScreen(
            action: CityEditAction.Remove,
            city: cityItem.cityName,
          ),
        ),
      ),
    );
  }
}
