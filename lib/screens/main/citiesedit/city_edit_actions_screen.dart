import 'package:flutter/material.dart';
import 'package:lets_play_cities/base/cities_list/cities_list_entry.dart';

import 'city_edit_action.dart';

/// Screen that allows to send requests to edit, add or remove a city
class CityEditActionsScreen extends StatelessWidget {
  final CitiesListEntry target;
  final CityEditAction action;

  const CityEditActionsScreen({
    Key? key,
    required this.action,
    required this.target,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}
