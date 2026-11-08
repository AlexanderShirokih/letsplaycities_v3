import 'package:flutter/material.dart';
import 'package:lets_play_cities/base/cities_list/city_item.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/common/d2/d2.dart';
import 'package:lets_play_cities/screens/game/cities_list.dart';

/// Place of a city row in its letter group. The group looks like one card, but
/// every row is a separate list item.
enum CityRowPosition {
  single,
  first,
  middle,
  last;

  bool get isFirst => this == single || this == first;

  bool get isLast => this == single || this == last;
}

enum _CityAction { edit, remove }

/// Letter above a group of cities
class CityLetterHeader extends StatelessWidget {
  final String letter;

  const CityLetterHeader(this.letter, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = D2Colors.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 8),
      child: Semantics(
        header: true,
        child: Text(
          letter,
          style: D2Text.display.copyWith(fontSize: 16, color: c.ink),
        ),
      ),
    );
  }
}

/// A city with its country and the menu with proposals to change it
class CityListItem extends StatelessWidget {
  final CityItem cityItem;
  final CityRowPosition position;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const CityListItem({
    super.key,
    required this.cityItem,
    required this.position,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final c = D2Colors.of(context);
    final t = context.t;
    final radius = Radius.circular(18);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.vertical(
          top: position.isFirst ? radius : Radius.zero,
          bottom: position.isLast ? radius : Radius.zero,
        ),
        border: position.isFirst
            ? null
            : Border(top: BorderSide(color: c.bg, width: 2)),
        boxShadow: position.isLast
            ? [BoxShadow(color: c.edge, offset: const Offset(0, 3))]
            : null,
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
                Text.rich(
                  cityNameSpans(cityItem.cityName, c, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  cityItem.country.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: D2Text.caption.copyWith(color: c.inkSoft),
                ),
              ],
            ),
          ),
          PopupMenuButton<_CityAction>(
            tooltip: t.citiesList.cityActions(city: cityItem.cityName),
            color: c.surface,
            surfaceTintColor: Colors.transparent,
            shadowColor: c.shadow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 236),
            onSelected: (action) => switch (action) {
              _CityAction.edit => onEdit(),
              _CityAction.remove => onRemove(),
            },
            itemBuilder: (_) => [
              _item(
                c,
                _CityAction.edit,
                D2Glyph.edit,
                t.citiesList.proposeEdit,
              ),
              _item(
                c,
                _CityAction.remove,
                D2Glyph.trash,
                t.citiesList.proposeRemove,
              ),
            ],
            child: SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: D2Icon(D2Glyph.more, size: 22, color: c.ink),
              ),
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<_CityAction> _item(
    D2Colors c,
    _CityAction action,
    D2Glyph glyph,
    String label,
  ) => PopupMenuItem(
    value: action,
    height: 48,
    child: Row(
      children: [
        D2Icon(glyph, size: 22, color: c.ink),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: D2Text.body.copyWith(fontSize: 15, color: c.ink),
          ),
        ),
      ],
    ),
  );
}
