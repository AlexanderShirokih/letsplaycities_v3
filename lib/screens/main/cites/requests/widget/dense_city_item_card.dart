import 'package:flutter/material.dart';
import 'package:lets_play_cities/screens/common/utils.dart';
import 'package:lets_play_cities/screens/main/cites/model/city_item.dart';

/// Displays a single city item with its country (both flag and name) as a
/// rounded card
class DenseCityItemCard extends StatelessWidget {
  final CityItem cityItem;

  const DenseCityItemCard({
    Key? key,
    required this.cityItem,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
      ),
      elevation: 4.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 10.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              cityItem.cityName,
              style: Theme.of(context).textTheme.subtitle2,
            ),
            const SizedBox(height: 4.0),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: theme.colorScheme.onPrimary,
                      style: BorderStyle.solid,
                      width: 1.0,
                    ),
                  ),
                  child: createFlagImage(cityItem.country.countryCode),
                ),
                const SizedBox(width: 7.0),
                Text(
                  cityItem.country.name,
                  style: theme.textTheme.subtitle2?.copyWith(
                    color: theme.textTheme.caption?.color,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
