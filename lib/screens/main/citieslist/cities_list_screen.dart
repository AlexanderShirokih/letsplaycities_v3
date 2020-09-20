import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lets_play_cities/base/cities_list/bloc/cities_list_bloc.dart';
import 'package:lets_play_cities/base/cities_list/cities_list_entry.dart';
import 'package:lets_play_cities/base/cities_list/cities_list_filter.dart';
import 'package:lets_play_cities/screens/common/common_widgets.dart';
import 'package:lets_play_cities/l18n/localization_service.dart';
import 'package:lets_play_cities/utils/debouncer.dart';
import 'package:lets_play_cities/utils/string_utils.dart';

/// Screen that shows list of all database cities
class CitiesListScreen extends StatefulWidget {
  @override
  _CitiesListScreenState createState() => _CitiesListScreenState();
}

class _CitiesListScreenState extends State<CitiesListScreen> {
  final TextEditingController _controller = TextEditingController();
  final Debouncer _cityFilterDebouncer = Debouncer(Duration(seconds: 1));
  final _citiesListBloc = CitiesListBloc();

  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final text = _controller.text;
      setState(() {
        _cityFilterDebouncer.run(() => _citiesListBloc.add(
            CitiesListFilteringEvent(CitiesListFilter(text.toLowerCase()))));
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _cityFilterDebouncer.cancel();
    _citiesListBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.repository<LocalizationService>();
    return Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () {
            if (isSearching)
              setState(() {
                isSearching = false;
              });
            else
              Navigator.maybePop(context);
          }),
          title: isSearching
              ? TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: l10n.citiesList['enter_city'],
                  ),
                )
              : Text(l10n.citiesList['title']),
          actions: isSearching
              ? [
                  if (_controller.text.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () => setState(() {
                        _controller.text = "";
                      }),
                    ),
                  _createFilterButton()
                ]
              : [
                  _createFilterButton(),
                  IconButton(
                    icon: Icon(Icons.search),
                    onPressed: () => setState(() {
                      isSearching = !isSearching;
                    }),
                  )
                ],
        ),
        body: BlocBuilder(
          cubit: _citiesListBloc,
          builder: (context, state) {
            if (state is CitiesListInitial) {
              return LoadingView(l10n.citiesList['loading'].toString());
            } else if (state is CitiesListDataState) {
              return _displayData(l10n, state);
            } else
              throw ("Unexpected state $state");
          },
        ));
  }

  Widget _displayData(LocalizationService l10n, CitiesListDataState data) =>
      ListView.builder(
          itemCount: data.citiesList.length + 1,
          itemBuilder: (context, index) => index == 0
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 0.0),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        child: RaisedButton(
                            onPressed: () {},
                            child: Text(l10n.citiesList['about'])),
                      ),
                      Divider(thickness: 2.0),
                    ],
                  ),
                )
              : _createListTile(l10n.citiesList['unk_city'], data,
                  data.citiesList[index - 1]));

  Widget _createListTile(String missingCountryText, CitiesListDataState data,
          CitiesListEntry entry) =>
      ListTile(
          leading: createFlagImage(entry.countryCode),
          title: Text(
            "${entry.cityName.toTitleCase()} (${data.countryList.firstWhere((county) => county.countryCode == entry.countryCode, orElse: () => null)?.name ?? missingCountryText})",
          ));

  Widget _createFilterButton() => IconButton(
        icon: Icon(Icons.filter_list),
        onPressed: () {},
      );
}
