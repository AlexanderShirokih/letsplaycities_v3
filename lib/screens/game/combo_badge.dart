import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lets_play_cities/base/game/combo.dart';
import 'package:lets_play_cities/i18n/enum_labels.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';

/// Used to display users combos.
class ComboBadgeWidget extends StatelessWidget {
  final Stream<Map<ComboType, int>> _comboEvents;

  const ComboBadgeWidget(this._comboEvents, {super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    return StreamBuilder<Map<ComboType, int>>(
      stream: _comboEvents,
      builder: (context, snap) => !snap.hasData
          ? Container()
          : Row(
              children: snap.requireData.entries
                  .map((e) => _createBadge(context, t, e.key, e.value))
                  .toList(growable: false),
            ),
    );
  }

  Widget _createBadge(
    BuildContext context,
    Translations t,
    ComboType comboType,
    int multiplier,
  ) => Tooltip(
    message: comboType.label(t),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: Chip(
        labelPadding: const EdgeInsets.symmetric(
          vertical: 1.0,
          horizontal: 1.0,
        ),
        avatar: CircleAvatar(
          backgroundColor: Colors.transparent,
          child: _getIcon(comboType, Theme.of(context).colorScheme.secondary),
        ),
        label: Text(
          '× $multiplier',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    ),
  );

  Widget _getIcon(ComboType type, Color color) {
    switch (type) {
      case ComboType.quickTime:
        return Icon(Icons.timelapse_outlined, color: color);
      case ComboType.shortWord:
        return Icon(Icons.star, color: color);
      case ComboType.longWord:
        return FaIcon(FontAwesomeIcons.rulerHorizontal, color: color);
      case ComboType.sameCountry:
        return FaIcon(FontAwesomeIcons.earthEurope, color: color);
      case ComboType.differentCountries:
        return FaIcon(FontAwesomeIcons.bookAtlas, color: color);
    }
  }
}
