import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lets_play_cities/base/cities_list/bloc/city_edit_actions_bloc.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/common/d2/d2.dart';
import 'package:lets_play_cities/screens/main/cites/requests/widget/dense_city_item_card.dart';

import 'common_fields.dart';

/// Layout for renaming the city.
/// Contains the following fields: new city name, new country name,
/// renaming reason
class RemoveCityLayout extends StatelessWidget {
  final TextEditingController reasonController;

  const RemoveCityLayout({super.key, required this.reasonController});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = D2Colors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          t.citiesRequest.removeCity,
          style: D2Text.section.copyWith(color: c.ink),
        ),
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
          t.citiesRequest.removeReason,
          style: D2Text.section.copyWith(color: c.ink),
        ),
        const SizedBox(height: 14.0),
        const SizedBox(height: 10.0),
        createRenameReasonField(
          context: context,
          t: t,
          placeholder: t.citiesRequest.removeReasonHint,
          textEditingController: reasonController,
        ),
        const SizedBox(height: 28.0),
        Text(
          t.citiesRequest.beforeSending,
          style: D2Text.section.copyWith(fontSize: 14, color: c.ink),
        ),
        const SizedBox(height: 8.0),
        createSuggestionRules(context, rules: t.citiesRequest.removingRules),
        const SizedBox(height: 46.0),
      ],
    );
  }
}
