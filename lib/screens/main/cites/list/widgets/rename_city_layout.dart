import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lets_play_cities/base/cities_list/bloc/city_edit_actions_bloc.dart';
import 'package:lets_play_cities/base/dictionary/country_entity.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/common/d2/d2.dart';
import 'package:lets_play_cities/screens/main/cites/requests/widget/dense_city_item_card.dart';

import 'common_fields.dart';

/// Layout for removing an existing city.
/// Contains the following fields: renaming reason
class RenameCityLayout extends StatelessWidget {
  final TextEditingController cityNameController;
  final TextEditingController reasonController;
  final CountryEntity? currentCountry;
  final void Function(CountryEntity) onCountryChanged;

  const RenameCityLayout({
    super.key,
    required this.cityNameController,
    required this.reasonController,
    required this.currentCountry,
    required this.onCountryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = D2Colors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(t.edit, style: D2Text.section.copyWith(color: c.ink)),
        const SizedBox(height: 14.0),
        BlocBuilder<CityEditActionsBloc, CityEditActionsState>(
          builder: (context, state) {
            if (state is CityEditActionsData) {
              return DenseCityItemCard(cityItem: state.cityItem);
            }
            return const SizedBox();
          },
        ),
        const SizedBox(height: 26.0),
        Text(
          t.citiesRequest.proposedChanges,
          style: D2Text.section.copyWith(color: c.ink),
        ),
        const SizedBox(height: 14.0),
        createCountryNameField(
          context: context,
          t: t,
          textEditingController: cityNameController,
        ),
        const SizedBox(height: 10.0),
        BlocBuilder<CityEditActionsBloc, CityEditActionsState>(
          builder: (context, state) {
            final allCountries = state is CityEditActionsData
                ? state.countryEntities
                : const <CountryEntity>[];

            return createCountrySelector(
              context: context,
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
          context: context,
          t: t,
          placeholder: t.citiesRequest.editReasonHint,
          textEditingController: reasonController,
        ),
        const SizedBox(height: 28.0),
        Text(
          t.citiesRequest.beforeSending,
          style: D2Text.section.copyWith(fontSize: 14, color: c.ink),
        ),
        const SizedBox(height: 8.0),
        createSuggestionRules(context, rules: t.citiesRequest.commonRules),
        const SizedBox(height: 46.0),
      ],
    );
  }
}
