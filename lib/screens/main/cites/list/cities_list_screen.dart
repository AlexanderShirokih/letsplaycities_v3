import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/base/cities_list/bloc/cities_list_bloc.dart';
import 'package:lets_play_cities/base/cities_list/cities_list_entry.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/remote/city_requests_repository.dart';
import 'package:lets_play_cities/screens/common/design/design.dart';
import 'package:lets_play_cities/screens/main/cites/list/country_filter_sheet.dart';
import 'package:lets_play_cities/screens/main/cites/list/requests_count_cubit.dart';
import 'package:lets_play_cities/screens/main/cites/list/widgets/city_list_item.dart';
import 'package:lets_play_cities/screens/main/cites/list/widgets/app_search_field.dart';
import 'package:lets_play_cities/screens/main/cites/model/city_edit_action.dart';
import 'package:lets_play_cities/screens/main/cites/requests/city_edit_actions_screen.dart';
import 'package:lets_play_cities/screens/main/cites/requests/city_requests_list_screen.dart';
import 'package:lets_play_cities/screens/root/root_screen.dart';

/// Position of the cities list among the root tabs
const citiesTabIndex = 1;

/// «Города» tab: the list of all database cities grouped by the first letter
class CitiesListScreen extends StatefulWidget {
  const CitiesListScreen({super.key});

  @override
  State<CitiesListScreen> createState() => _CitiesListScreenState();
}

class _CitiesListScreenState extends State<CitiesListScreen> {
  late final CitiesListBloc _bloc = CitiesListBloc(
    GetIt.instance.get(),
    GetIt.instance.get(),
  );
  late final RequestsCountCubit _requests = RequestsCountCubit(
    GetIt.instance.get<CityRequestsRepository>(),
  );

  ValueListenable<int>? _visibleTab;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final listenable = RootScreen.maybeOf(context)?.selectedIndex;
    if (listenable != _visibleTab) {
      _visibleTab?.removeListener(_onTabChanged);
      _visibleTab = listenable?..addListener(_onTabChanged);
    }
  }

  @override
  void dispose() {
    _visibleTab?.removeListener(_onTabChanged);
    _bloc.close();
    _requests.close();
    super.dispose();
  }

  /// The requests may have been reviewed while another tab was shown
  void _onTabChanged() {
    if (_visibleTab?.value == citiesTabIndex) _requests.refresh();
  }

  Future<void> _push(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    _requests.refresh();
  }

  Future<void> _pickCountries(CitiesListState state) async {
    if (state is! CitiesListDataState) return;

    final prefs = context.read<GamePreferences>();
    final filter = state is CitiesListFilteredDataState
        ? state.filter.countryFilter
        : null;

    final picked = await showCountryFilterSheet(
      context,
      countries: state.countryList,
      selected: filter == null || filter.isAllPresent
          ? null
          : filter.allowedCountryCodes,
      recent: prefs.recentCountries,
    );
    if (picked == null) return;

    _bloc.add(CitiesListUpdateCountryFilterEvent(picked));
    if (!picked.isAllPresent) {
      prefs.recentCountries = [
        ...picked.allowedCountryCodes,
        ...prefs.recentCountries.where(
          (code) => !picked.allowedCountryCodes.contains(code),
        ),
      ].take(maxRecentCountries).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = AppColors.of(context);

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _bloc),
        BlocProvider.value(value: _requests),
      ],
      child: Material(
        color: c.bg,
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              BlocBuilder<CitiesListBloc, CitiesListState>(
                builder: (context, state) => Column(
                  children: [
                    _Header(onRequests: () => _push(CityRequestsListScreen())),
                    _SearchRow(
                      state: state,
                      onChanged: (text) => _bloc.add(
                        CitiesListUpdateNameFilter(text.toLowerCase()),
                      ),
                      onPickCountries: () => _pickCountries(state),
                    ),
                    Expanded(
                      child: state is CitiesListDataState
                          ? _CitiesList(
                              data: state,
                              onEdit: (city) => _push(
                                CityEditActionsScreen(
                                  action: CityEditAction.edit,
                                  city: city,
                                ),
                              ),
                              onRemove: (city) => _push(
                                CityEditActionsScreen(
                                  action: CityEditAction.remove,
                                  city: city,
                                ),
                              ),
                            )
                          : Center(
                              child: CircularProgressIndicator(color: c.violet),
                            ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 18,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: AppButton(
                    label: t.citiesList.proposeCity,
                    icon: AppGlyph.plus,
                    onPressed: () => _push(
                      CityEditActionsScreen(action: CityEditAction.add),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onRequests;

  const _Header({required this.onRequests});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = AppColors.of(context);

    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                t.citiesList.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.display.copyWith(fontSize: 22, color: c.ink),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Align(
                alignment: Alignment.centerRight,
                child: BlocBuilder<RequestsCountCubit, int?>(
                  builder: (context, count) => AppButton(
                    label: t.citiesList.myRequests,
                    kind: AppButtonKind.secondary,
                    badge: count,
                    onPressed: onRequests,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchRow extends StatelessWidget {
  final CitiesListState state;
  final ValueChanged<String> onChanged;
  final VoidCallback onPickCountries;

  const _SearchRow({
    required this.state,
    required this.onChanged,
    required this.onPickCountries,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final selected = state is CitiesListFilteredDataState
        ? (state as CitiesListFilteredDataState).filter.countryFilter
        : null;
    final label = selected == null || selected.isAllPresent
        ? t.citiesList.allCountries
        : t.citiesList.countriesN(count: selected.allowedCountryCodes.length);

    return Padding(
      // The gap keeps the scrolled list off the search field
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: LayoutBuilder(
        builder: (context, constraints) => Row(
          children: [
            Expanded(
              child: AppSearchField(
                hint: t.citiesList.searchHint,
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: 10),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.5),
              child: AppButton(
                label: label,
                icon: AppGlyph.countries,
                kind: AppButtonKind.secondary,
                onPressed: state is CitiesListDataState
                    ? onPickCountries
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A line of the flat list: a letter or a city
sealed class _Line {
  const _Line();
}

class _Letter extends _Line {
  final String letter;

  const _Letter(this.letter);
}

class _City extends _Line {
  final CitiesListEntry entry;
  final CityRowPosition position;

  const _City(this.entry, this.position);
}

/// Space under the list for the floating button
const _listBottomPadding = 88.0;

class _CitiesList extends StatefulWidget {
  final CitiesListDataState data;
  final ValueChanged<String> onEdit;
  final ValueChanged<String> onRemove;

  const _CitiesList({
    required this.data,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  State<_CitiesList> createState() => _CitiesListState();
}

class _CitiesListState extends State<_CitiesList> {
  late List<_Line> _lines = _group(widget.data.citiesList);

  @override
  void didUpdateWidget(_CitiesList old) {
    super.didUpdateWidget(old);

    if (!identical(old.data.citiesList, widget.data.citiesList)) {
      _lines = _group(widget.data.citiesList);
    }
  }

  /// Entries come sorted by name, so the first letters are already together
  List<_Line> _group(List<CitiesListEntry> cities) {
    final lines = <_Line>[];

    for (var i = 0; i < cities.length; i++) {
      final letter = _letterOf(cities[i]);
      final isFirst = i == 0 || _letterOf(cities[i - 1]) != letter;
      final isLast =
          i == cities.length - 1 || _letterOf(cities[i + 1]) != letter;

      if (isFirst) lines.add(_Letter(letter));
      lines.add(
        _City(cities[i], switch ((isFirst, isLast)) {
          (true, true) => CityRowPosition.single,
          (true, false) => CityRowPosition.first,
          (false, true) => CityRowPosition.last,
          (false, false) => CityRowPosition.middle,
        }),
      );
    }

    return lines;
  }

  String _letterOf(CitiesListEntry entry) =>
      entry.cityName.substring(0, 1).toUpperCase();

  @override
  Widget build(BuildContext context) {
    final missingCountry = context.t.citiesList.unkCity;

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: _listBottomPadding),
      itemCount: _lines.length,
      itemBuilder: (context, index) => switch (_lines[index]) {
        _Letter(:final letter) => CityLetterHeader(letter),
        _City(:final entry, :final position) => _buildCity(
          entry,
          position,
          missingCountry,
        ),
      },
    );
  }

  Widget _buildCity(
    CitiesListEntry entry,
    CityRowPosition position,
    String missingCountry,
  ) {
    final item = widget.data.getCityItem(entry, missingCountry);

    return CityListItem(
      key: ObjectKey(entry),
      cityItem: item,
      position: position,
      onEdit: () => widget.onEdit(item.cityName),
      onRemove: () => widget.onRemove(item.cityName),
    );
  }
}
