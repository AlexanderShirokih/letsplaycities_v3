import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lets_play_cities/base/game/combo.dart';
import 'package:lets_play_cities/l18n/localization_service.dart';

/// Used to display users combos.
class ComboBadgeWidget extends StatelessWidget {
  final Stream<Map<ComboType, int>> _comboEvents;

  ComboBadgeWidget(this._comboEvents);

  @override
  Widget build(BuildContext context) {
    final comboNames = (context.repository<LocalizationService>().game['combos']
            as List<dynamic>)
        .cast<String>();

    return StreamBuilder<Map<ComboType, int>>(
      stream: _comboEvents,
      builder: (context, snap) => !snap.hasData
          ? Container()
          : Row(
              children: snap.data.entries
                  .map((e) => _createBadge(context, comboNames, e.key, e.value))
                  .toList(growable: false),
            ),
    );
  }

  Widget _createBadge(BuildContext context, List<String> comboNames,
          ComboType comboType, int multiplier) =>
      Tooltip(
        message: comboNames[comboType.index],
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          child: Chip(
            labelPadding:
                const EdgeInsets.symmetric(vertical: 1.0, horizontal: 1.0),
            avatar: CircleAvatar(
              backgroundColor: Colors.transparent,
              child: _getIcon(comboType, Theme.of(context).accentColor),
            ),
            label: Text(
              "× $multiplier",
              style: Theme.of(context).textTheme.caption,
            ),
          ),
        ),
      );

  Widget _getIcon(ComboType type, Color color) {
    switch (type) {
      case ComboType.QUICK_TIME:
        return Icon(Icons.timelapse_outlined, color: color);
      case ComboType.SHORT_WORD:
        return Icon(Icons.star, color: color);
      case ComboType.LONG_WORD:
        return FaIcon(FontAwesomeIcons.rulerHorizontal, color: color);
      case ComboType.SAME_COUNTRY:
        return FaIcon(FontAwesomeIcons.globeEurope, color: color);
      case ComboType.DIFFERENT_COUNTRIES:
        return FaIcon(FontAwesomeIcons.atlas, color: color);
    }
    throw ("Bad state!");
  }
}
