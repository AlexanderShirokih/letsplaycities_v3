import 'package:flutter/material.dart';
import 'package:lets_play_cities/base/cities_list/city_item.dart';
import 'package:lets_play_cities/screens/common/d2/d2.dart';
import 'package:lets_play_cities/screens/game/cities_list.dart';

/// Displays a single city item with its country (both flag and name) as a
/// rounded card
class DenseCityItemCard extends StatelessWidget {
  final CityItem cityItem;

  const DenseCityItemCard({super.key, required this.cityItem});

  @override
  Widget build(BuildContext context) {
    final c = D2Colors.of(context);

    return SizedBox(
      width: double.infinity,
      child: D2Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(cityItem.cityName, style: D2Text.body.copyWith(color: c.ink)),
            const SizedBox(height: 4.0),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CityFlag(
                  cityItem.country.countryCode,
                  width: 28,
                  height: 20,
                  radius: 4,
                ),
                const SizedBox(width: 8.0),
                Flexible(
                  child: Text(
                    cityItem.country.name,
                    style: D2Text.caption.copyWith(color: c.inkSoft),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
