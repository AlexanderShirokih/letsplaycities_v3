import 'package:flutter/material.dart';
import 'package:lets_play_cities/base/cities_list/cities_list_entry.dart';
import 'package:lets_play_cities/screens/common/utils.dart';
import 'package:lets_play_cities/utils/string_utils.dart';

/// Callback used to provide a country name
typedef ProvideCountryName = String Function(int countryCode);

/// Shows city with its country. Has submenu activated by tap,
/// that allows to edit the city.
class CityListItem extends StatelessWidget {
  final CitiesListEntry cityEntry;
  final ProvideCountryName provideCountryName;
  final bool expanded;
  final void Function() onTap;
  final void Function() onEdit;
  final void Function() onRemove;

  const CityListItem({
    Key? key,
    required this.onTap,
    required this.onEdit,
    required this.onRemove,
    required this.expanded,
    required this.cityEntry,
    required this.provideCountryName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final countryCode = cityEntry.countryCode;
    final cityName = cityEntry.cityName.toTitleCase();
    final countryName = provideCountryName(countryCode);

    final title = '$cityName ($countryName)';

    final content = ListTile(
      onTap: onTap,
      leading: createFlagImage(countryCode),
      title: Text(title),
    );
    return expanded
        ? Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                content,
                if (expanded) Divider(),
                AnimatedContainer(
                  height: expanded ? 40 : 0,
                  duration: const Duration(milliseconds: 800),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      // Want edit
                      TextButton.icon(
                        icon: Icon(Icons.edit),
                        label: Text('Нужно изменить страну или название'),
                        onPressed: onEdit,
                      ),
                      // Want remove
                      TextButton.icon(
                        icon: Icon(Icons.remove_circle_outline),
                        label: Text('Нужно удалить'),
                        onPressed: onRemove,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        : content;
  }
}
