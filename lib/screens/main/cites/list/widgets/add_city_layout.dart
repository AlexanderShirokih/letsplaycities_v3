import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lets_play_cities/base/cities_list/bloc/city_edit_actions_bloc.dart';
import 'package:lets_play_cities/base/dictionary/country_entity.dart';
import 'package:lets_play_cities/l18n/localization_service.dart';

import 'common_fields.dart';

/// Layout for adding a new city.
/// Contains the following fields: new city name, new country name,
/// adding reason
class AddCityLayout extends StatelessWidget {
  final LocalizationService l10n;
  final TextEditingController cityNameController;
  final TextEditingController reasonController;
  final CountryEntity? currentCountry;
  final void Function(CountryEntity) onCountryChanged;

  const AddCityLayout({
    Key? key,
    required this.l10n,
    required this.cityNameController,
    required this.reasonController,
    required this.currentCountry,
    required this.onCountryChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          'Добавить город',
          style: Theme.of(context).textTheme.headline6,
        ),
        const SizedBox(height: 14.0),
        createCountryNameField(
          textEditingController: cityNameController,
        ),
        const SizedBox(height: 10.0),
        BlocBuilder<CityEditActionsBloc, CityEditActionsState>(
            builder: (context, state) {
          final allCountries = state is CityEditActionsData
              ? state.countryEntities
              : const <CountryEntity>[];

          return createCountrySelector(
            countries: allCountries,
            isLoading: allCountries.isEmpty,
            current: currentCountry,
            onCountryChanged: onCountryChanged,
          );
        }),
        const SizedBox(height: 10.0),
        createRenameReasonField(
          placeholder: 'Причина добавления или ссылка на источник',
          textEditingController: reasonController,
        ),
        const SizedBox(height: 28.0),
        Text(
          'Перед отправкой заявки убедитесь в следующем',
          style: Theme.of(context).textTheme.subtitle2,
        ),
        const SizedBox(height: 8.0),
        createSuggestionRules(
          context,
          rules: (l10n.citiesRequest['common_rules'] as List<dynamic>)
              .cast<String>(),
        ),
        const SizedBox(height: 46.0),
      ],
    );
  }
}
