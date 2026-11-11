import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lets_play_cities/base/cities_list/bloc/city_edit_actions_bloc.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/common/design/design.dart';
import 'package:lets_play_cities/screens/main/cites/requests/widget/dense_city_item_card.dart';

import 'common_fields.dart';

/// Layout for removing an existing city.
/// Contains the current city, the removing reason and a way to propose an
/// edit instead
class RemoveCityLayout extends StatelessWidget {
  final TextEditingController reasonController;

  /// Replaces the screen with the edit form
  final VoidCallback onProposeEdit;

  const RemoveCityLayout({
    super.key,
    required this.reasonController,
    required this.onProposeEdit,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = AppColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlocBuilder<CityEditActionsBloc, CityEditActionsState>(
          builder: (context, state) {
            if (state is CityEditActionsData) {
              return DenseCityItemCard(cityItem: state.cityItem);
            }
            return const SizedBox();
          },
        ),
        const SizedBox(height: 14),
        createRenameReasonField(
          context: context,
          t: t,
          textEditingController: reasonController,
        ),
        const SizedBox(height: 18),
        createSuggestionRules(context, rules: t.citiesRequest.removingRules),
        const SizedBox(height: 4),
        TextButton(
          onPressed: onProposeEdit,
          style: TextButton.styleFrom(
            foregroundColor: c.violet,
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: 2),
            alignment: Alignment.centerLeft,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: AppText.body.copyWith(
              fontSize: 14,
              decoration: TextDecoration.underline,
            ),
          ),
          child: Text(t.citiesList.proposeEdit),
        ),
      ],
    );
  }
}
