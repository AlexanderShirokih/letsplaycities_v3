import 'package:flutter/material.dart';
import 'package:lets_play_cities/base/cities_list/city_item.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/common/design/design.dart';
import 'package:lets_play_cities/screens/game/cities_list.dart';

/// Displays the city the request is about, with its country, in an outlined
/// box under the «currently in the dictionary» caption
class DenseCityItemCard extends StatelessWidget {
  final CityItem cityItem;

  const DenseCityItemCard({super.key, required this.cityItem});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            context.t.citiesRequest.currentCity,
            style: AppText.bodyRegular.copyWith(fontSize: 14, color: c.inkSoft),
          ),
        ),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.edge, width: 2),
          ),
          child: Row(
            children: [
              CityFlag(
                cityItem.country.countryCode,
                width: 28,
                height: 20,
                radius: 4,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cityItem.cityName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body.copyWith(height: 1.25, color: c.ink),
                    ),
                    Text(
                      cityItem.country.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption.copyWith(
                        height: 1.25,
                        color: c.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
