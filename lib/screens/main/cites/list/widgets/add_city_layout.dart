import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lets_play_cities/base/cities_list/bloc/city_edit_actions_bloc.dart';
import 'package:lets_play_cities/base/dictionary/country_entity.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';

import 'common_fields.dart';

/// Layout for adding a new city.
/// Contains the following fields: new city name, new country name,
/// adding reason
class AddCityLayout extends StatelessWidget {
  final TextEditingController cityNameController;
  final TextEditingController reasonController;
  final CountryEntity? currentCountry;
  final void Function(CountryEntity) onCountryChanged;

  const AddCityLayout({
    super.key,
    required this.cityNameController,
    required this.reasonController,
    required this.currentCountry,
    required this.onCountryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          t.citiesRequest.addCity,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 14.0),
        createCountryNameField(t: t, textEditingController: cityNameController),
        const SizedBox(height: 10.0),
        BlocBuilder<CityEditActionsBloc, CityEditActionsState>(
          builder: (context, state) {
            final allCountries = state is CityEditActionsData
                ? state.countryEntities
                : const <CountryEntity>[];

            return createCountrySelector(
              t: t,
              countries: allCountries,
              isLoading: allCountries.isEmpty,
              current: currentCountry,
              onCountryChanged: onCountryChanged,
            );
          },
        ),
        const SizedBox(height: 10.0),
        createRenameReasonField(
          t: t,
          placeholder: t.citiesRequest.addReasonHint,
          textEditingController: reasonController,
        ),
        const SizedBox(height: 28.0),
        Text(
          t.citiesRequest.beforeSending,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8.0),
        createSuggestionRules(context, rules: t.citiesRequest.commonRules),
        const SizedBox(height: 46.0),
      ],
    );
  }
}
