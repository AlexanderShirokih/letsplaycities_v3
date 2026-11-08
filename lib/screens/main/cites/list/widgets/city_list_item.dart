import 'package:flutter/material.dart';
import 'package:lets_play_cities/base/cities_list/city_item.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/common/utils.dart';

/// Shows city with its country. Has submenu activated by tap,
/// that allows to edit the city.
class CityListItem extends StatelessWidget {
  final CityItem cityItem;
  final bool expanded;
  final void Function() onTap;
  final void Function() onEdit;
  final void Function() onRemove;

  const CityListItem({
    super.key,
    required this.onTap,
    required this.onEdit,
    required this.onRemove,
    required this.expanded,
    required this.cityItem,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final cityName = cityItem.cityName;
    final countryName = cityItem.country.name;
    final countryCode = cityItem.country.countryCode;

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
                        label: Text(t.citiesList.wantEdit),
                        onPressed: onEdit,
                      ),
                      // Want remove
                      TextButton.icon(
                        icon: Icon(Icons.remove_circle_outline),
                        label: Text(t.citiesList.wantRemove),
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
