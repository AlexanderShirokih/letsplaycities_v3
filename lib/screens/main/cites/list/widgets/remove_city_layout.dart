import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lets_play_cities/base/cities_list/bloc/city_edit_actions_bloc.dart';
import 'package:lets_play_cities/l18n/localization_service.dart';
import 'package:lets_play_cities/screens/main/cites/requests/widget/dense_city_item_card.dart';

import 'common_fields.dart';

/// Layout for renaming the city.
/// Contains the following fields: new city name, new country name,
/// renaming reason
class RemoveCityLayout extends StatelessWidget {
  final LocalizationService l10n;
  final TextEditingController reasonController;

  const RemoveCityLayout({
    Key? key,
    required this.l10n,
    required this.reasonController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          'Удалить город',
          style: Theme.of(context).textTheme.headline6,
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
          'Причина удаления',
          style: Theme.of(context).textTheme.headline6,
        ),
        const SizedBox(height: 14.0),
        const SizedBox(height: 10.0),
        createRenameReasonField(
          placeholder: 'Причина удаления или ссылка на источник',
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
          rules: (l10n.citiesRequest['removing_rules'] as List<dynamic>)
              .cast<String>(),
        ),
        const SizedBox(height: 46.0),
      ],
    );
  }
}
