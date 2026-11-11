import 'package:flutter/material.dart';
import 'package:lets_play_cities/base/game/combo.dart';
import 'package:lets_play_cities/i18n/enum_labels.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/common/design/design.dart';

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
          ? const SizedBox.shrink()
          : Wrap(
              alignment: WrapAlignment.center,
              spacing: 4,
              runSpacing: 4,
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
  ) {
    final onYellow = AppColors.light.ink;

    return Tooltip(
      message: comboType.label(t),
      child: Container(
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: AppColors.of(context).yellow,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(glyphOf(comboType), size: 14, color: onYellow),
            const SizedBox(width: 3),
            Text(
              '×$multiplier',
              style: AppText.small.copyWith(color: onYellow, height: 1),
            ),
          ],
        ),
      ),
    );
  }

  /// The icon of a combo [type]
  static AppGlyph glyphOf(ComboType type) => switch (type) {
    ComboType.quickTime => AppGlyph.bolt,
    ComboType.shortWord => AppGlyph.star,
    ComboType.longWord => AppGlyph.gauge,
    ComboType.sameCountry => AppGlyph.cities,
    ComboType.differentCountries => AppGlyph.globe,
  };
}
