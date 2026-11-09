import 'package:flutter/material.dart';
import 'package:lets_play_cities/base/game/combo.dart';
import 'package:lets_play_cities/base/game/game_summary.dart';
import 'package:lets_play_cities/i18n/enum_labels.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/common/d2/d2.dart';
import 'package:lets_play_cities/screens/game/cities_list.dart';
import 'package:lets_play_cities/screens/game/combo_badge.dart';
import 'package:lets_play_cities/utils/minutes_seconds.dart';
import 'package:lets_play_cities/utils/string_utils.dart';

/// A [value] with its [label] below
class ResultMetric extends StatelessWidget {
  final String label;
  final Widget value;

  const ResultMetric({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final c = D2Colors.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 10, 6, 11),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          value,
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: D2Text.small.copyWith(
              fontWeight: FontWeight.w400,
              color: c.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}

/// The best level of one combo type
class ResultComboCard extends StatelessWidget {
  final ComboType type;
  final int level;

  const ResultComboCard(this.type, this.level, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = D2Colors.of(context);
    final t = context.t;
    final tile = switch (type) {
      ComboType.quickTime => c.yellow,
      ComboType.shortWord => c.sky,
      ComboType.longWord => c.orange,
      ComboType.sameCountry => c.edge,
      ComboType.differentCountries => c.mint,
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 11),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: c.edge, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: tile,
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: D2Icon(
              ComboBadgeWidget.glyphOf(type),
              size: 22,
              color: D2Colors.light.ink,
              strokeWidth: 2.25,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            type.label(t),
            style: D2Text.small.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: c.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            t.gameResults.comboTimes(count: ComboSystem.badgeValue(level)),
            style: D2Text.small.copyWith(
              fontWeight: FontWeight.w400,
              color: c.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}

/// Cities, time and the longest city of a game
class ResultMetrics extends StatelessWidget {
  final GameSummary summary;

  const ResultMetrics(this.summary, {super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    final c = D2Colors.of(context);
    final longest = summary.longestCity;

    return D2Card(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: ResultMetric(
                    label: t.gameResults.cities,
                    value: Text(
                      '${summary.citiesCount}',
                      style: D2Text.title.copyWith(fontSize: 20, color: c.ink),
                    ),
                  ),
                ),
                Container(width: 2, color: c.bg),
                Expanded(
                  child: ResultMetric(
                    label: t.gameResults.time,
                    value: Text(
                      formatClock(summary.duration.inSeconds),
                      style: D2Text.title.copyWith(fontSize: 20, color: c.ink),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (longest != null) ...[
            Container(height: 2, color: c.bg),
            ResultMetric(
              label: t.gameResults.longestCity,
              value: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (longest.countryCode > 0) ...[
                    CityFlag(longest.countryCode),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text.rich(
                      cityNameSpans(longest.city.toTitleCase(), c),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Up to three combo types with the highest levels, the best first
List<MapEntry<ComboType, int>> bestCombosOf(GameSummary summary) =>
    (summary.bestCombos.entries.where((e) => e.value > 0).toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(3)
        .toList();

/// A row of cards of the [best] combos
class ResultCombos extends StatelessWidget {
  final List<MapEntry<ComboType, int>> best;

  const ResultCombos(this.best, {super.key});

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, e) in best.indexed) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: ResultComboCard(e.key, e.value)),
        ],
      ],
    ),
  );
}
