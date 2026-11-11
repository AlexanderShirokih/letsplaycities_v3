import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'package:lets_play_cities/base/repositories/cities/country_repository.dart';
import 'package:lets_play_cities/base/scoring.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/common/design/design.dart';
import 'package:lets_play_cities/screens/game/cities_list.dart';
import 'package:lets_play_cities/utils/string_utils.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  /// Country names by country code, as the countries group keys them
  late final Future<Map<String, String>> _countryNames = GetIt.instance
      .get<CountryRepository>()
      .getCountryList()
      .then((list) => {for (final c in list) '${c.countryCode}': c.name});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final scoringSet = _getOrCreate(context.watch<GamePreferences>());

    return Scaffold(
      backgroundColor: AppColors.of(context).bg,
      body: SafeArea(
        child: Column(
          children: [
            AppScreenHeader(
              title: t.stats.title,
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: FutureBuilder<Map<String, String>>(
                future: _countryNames,
                builder: (context, names) =>
                    _StatisticsList(t, scoringSet, names.data ?? const {}),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ScoringSet _getOrCreate(GamePreferences prefs) {
    final data = prefs.scoringData;
    return data.isEmpty
        ? ScoringSet.initial()
        : ScoringSet.fromJson(jsonDecode(data));
  }
}

/// Number of countries shown before the "more" button
const _countriesPreview = 5;

class _StatisticsList extends StatefulWidget {
  final Translations t;
  final ScoringSet scoringSet;
  final Map<String, String> countryNames;

  const _StatisticsList(this.t, this.scoringSet, this.countryNames);

  @override
  State<_StatisticsList> createState() => _StatisticsListState();
}

class _StatisticsListState extends State<_StatisticsList> {
  bool _allCountries = false;

  Translations get _t => widget.t;

  @override
  Widget build(BuildContext context) {
    final groups = widget.scoringSet.groups;
    final total = _intOf(groups, groupParts);

    if (total == 0) {
      return AppEmptyState(
        art: const AppBarsArt(),
        title: _t.stats.emptyTitle,
        text: _t.stats.emptyText,
      );
    }

    final sections = [
      for (final group in groups) ?_buildSection(context, group, total),
    ];

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      itemCount: sections.length,
      separatorBuilder: (_, _) => const SizedBox(height: 18),
      itemBuilder: (_, i) => sections[i],
    );
  }

  /// Section of the [group] or `null` when the group is unknown or has no
  /// values
  Widget? _buildSection(BuildContext context, ScoringGroup group, int total) {
    return switch (group.main.name) {
      groupParts => _buildParts(group, total),
      groupOnline => _buildOnline(group),
      groupCombo => _buildCombo(group),
      groupFrequentCities => _buildFrequent(group),
      groupBigCities => _buildBig(group),
      groupCountries => _buildCountries(group),
      _ => null,
    };
  }

  Widget _buildParts(ScoringGroup group, int total) {
    final c = AppColors.of(context);
    final modes = [
      (fieldAndroid, c.violet),
      (fieldOnline, c.orange),
      (fieldPlayer, c.yellow),
      (fieldNetwork, c.sky),
    ];
    final segments = [
      for (final (name, color) in modes)
        if (_valueOf(group, name) > 0) (_valueOf(group, name), color),
    ];

    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                flex: 2,
                child: Text(
                  '$total',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.display.copyWith(fontSize: 40, color: c.ink),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _t.stats.games(count: total),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body.copyWith(fontSize: 15, color: c.inkSoft),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ExcludeSemantics(
            child: Container(
              key: const ValueKey('stats-mode-bar'),
              height: 18,
              // The outline is painted over the fill, and both are rounded
              // by the same radius: a fill inset by the border would be
              // clipped by the outer radius and leave gaps in the corners.
              foregroundDecoration: BoxDecoration(
                border: Border.all(color: c.shadow, width: 2),
                borderRadius: BorderRadius.circular(9),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Row(
                  // The segments have no child to take the height from
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, (count, color)) in segments.indexed)
                      Expanded(
                        flex: count,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: color,
                            border: i == 0
                                ? null
                                : Border(
                                    left: BorderSide(color: c.shadow, width: 2),
                                  ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          for (final (name, color) in modes)
            _LegendRow(
              color: color,
              name: _t.stats.fields[name] ?? name,
              value: _valueOf(group, name),
            ),
        ],
      ),
    );
  }

  Widget? _buildOnline(ScoringGroup group) {
    final wins = _valueOf(group, fieldWins);
    final losses = _valueOf(group, fieldLose);
    final seconds = _valueOf(group, fieldTime);

    if (wins == 0 && losses == 0 && seconds == 0) {
      return null;
    }

    final c = AppColors.of(context);
    final hours = seconds ~/ 3600;
    final minutes = seconds % 3600 ~/ 60;
    final time = hours > 0
        ? _t.stats.durationHm(hours: hours, minutes: minutes)
        : _t.stats.durationM(minutes: minutes);

    return _Section(
      title: _t.stats.groups[groupOnline]!,
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _Metric(wins, _t.stats.wins(count: wins))),
                  Container(width: 2, color: c.bg),
                  Expanded(
                    child: _Metric(losses, _t.stats.losses(count: losses)),
                  ),
                ],
              ),
            ),
            Container(height: 2, color: c.bg),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        _t.stats.timeInGame,
                        style: AppText.bodyRegular.copyWith(
                          fontSize: 14,
                          color: c.inkSoft,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      time,
                      style: AppText.body.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontVariations: const [FontVariation('wght', 700)],
                        color: c.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildCombo(ScoringGroup group) {
    if (!group.child.any((f) => _intField(f) > 0)) {
      return null;
    }

    final c = AppColors.of(context);
    final tiles = {
      fieldQuickTime: (c.yellow, AppColors.light.ink, AppGlyph.bolt),
      fieldShortWord: (c.sky, AppColors.light.ink, AppGlyph.star),
      fieldLongWord: (c.orange, AppColors.light.ink, AppGlyph.gauge),
      fieldSameCountry: (c.edge, c.ink, AppGlyph.cities),
      fieldDiffCountry: (c.mint, AppColors.light.ink, AppGlyph.globe),
    };

    return _Section(
      title: _t.stats.groups[groupCombo]!,
      child: _RowCard(
        rows: [
          for (final field in group.child)
            if (tiles[field.name] case (
              final color,
              final onColor,
              final glyph,
            ))
              _StatRow(
                lead: _GlyphTile(color: color, onColor: onColor, glyph: glyph),
                name: _t.stats.fields[field.name] ?? field.name,
                value: '${_intField(field)}',
              ),
        ],
      ),
    );
  }

  Widget? _buildFrequent(ScoringGroup group) {
    final cities = _pairs(group);

    if (cities.isEmpty) {
      return null;
    }

    return _Section(
      title: _t.stats.groups[groupFrequentCities]!,
      child: _RowCard(
        rows: [
          for (final (i, (name, count)) in cities.indexed)
            _BarRow(
              lead: _Rank(i + 1),
              name: name.toTitleCase(),
              count: count,
              max: cities.map((e) => e.$2).reduce(math.max),
            ),
        ],
      ),
    );
  }

  Widget? _buildBig(ScoringGroup group) {
    final cities = _pairs(group);

    if (cities.isEmpty) {
      return null;
    }

    return _Section(
      title: _t.stats.groups[groupBigCities]!,
      child: _RowCard(
        rows: [
          for (final (name, count) in cities)
            _StatRow(name: name.toTitleCase(), value: '$count', padStart: 14),
        ],
      ),
    );
  }

  Widget? _buildCountries(ScoringGroup group) {
    final countries = _pairs(group)..sort((a, b) => b.$2.compareTo(a.$2));

    if (countries.isEmpty) {
      return null;
    }

    final c = AppColors.of(context);
    final max = countries.first.$2;
    final shown = _allCountries
        ? countries
        : countries.take(_countriesPreview).toList();
    final rest = countries.length - shown.length;

    return _Section(
      title: _t.stats.groups[groupCountries]!,
      count: countries.length,
      child: Column(
        children: [
          _RowCard(
            rows: [
              for (final (code, count) in shown)
                _BarRow(
                  lead: int.tryParse(code) == null
                      ? const SizedBox(width: 28, height: 20)
                      : CityFlag(
                          int.parse(code),
                          width: 28,
                          height: 20,
                          radius: 4,
                        ),
                  name: widget.countryNames[code] ?? code,
                  count: count,
                  max: max,
                ),
            ],
          ),
          if (rest > 0)
            InkWell(
              onTap: () => setState(() => _allCountries = true),
              borderRadius: BorderRadius.circular(12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          _t.profile.moreCountries(count: rest),
                          style: AppText.body.copyWith(
                            fontSize: 14,
                            color: c.violet,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      AppIcon(AppGlyph.chevron, size: 18, color: c.violet),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Fields of the paired [group] that have a value, as (key, value)
  List<(String, int)> _pairs(ScoringGroup group) => [
    for (final field in group.child)
      if (field is PairedScoringField<String, int> &&
          field.key != null &&
          field.value != null)
        (field.key!, field.value!),
  ];

  int _intOf(List<ScoringGroup> groups, String name) {
    for (final group in groups) {
      if (group.main.name == name) {
        return _intField(group.main);
      }
    }

    return 0;
  }

  int _valueOf(ScoringGroup group, String name) {
    for (final field in group.child) {
      if (field.name == name) {
        return _intField(field);
      }
    }

    return 0;
  }

  int _intField(ScoringField field) =>
      field is IntScoringField ? field.value ?? 0 : 0;
}

class _Section extends StatelessWidget {
  final String title;
  final int? count;
  final Widget child;

  const _Section({required this.title, this.count, required this.child});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.section.copyWith(color: c.ink),
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 8),
                Text(
                  '$count',
                  style: AppText.body.copyWith(fontSize: 14, color: c.inkSoft),
                ),
              ],
            ],
          ),
        ),
        child,
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String name;
  final int value;

  const _LegendRow({
    required this.color,
    required this.name,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 28),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: c.shadow, width: 1.5),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.bodyRegular.copyWith(fontSize: 14, color: c.ink),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$value',
            style: AppText.body.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontVariations: const [FontVariation('wght', 700)],
              color: c.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final int value;
  final String label;

  const _Metric(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      child: Column(
        children: [
          Text(
            '$value',
            style: AppText.title.copyWith(fontSize: 20, color: c.ink),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppText.small.copyWith(
              fontWeight: FontWeight.w400,
              fontVariations: const [FontVariation('wght', 400)],
              height: 1.25,
              color: c.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}

/// Card with [rows] separated by lines
class _RowCard extends StatelessWidget {
  final List<Widget> rows;

  const _RowCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final (i, row) in rows.indexed) ...[
            if (i > 0) Container(height: 2, color: c.bg),
            row,
          ],
        ],
      ),
    );
  }
}

/// 50 px row: optional [lead], [name] and [value]
class _StatRow extends StatelessWidget {
  final Widget? lead;
  final String name;
  final String value;
  final double padStart;

  const _StatRow({
    this.lead,
    required this.name,
    required this.value,
    this.padStart = 10,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 50),
      child: Padding(
        padding: EdgeInsets.fromLTRB(padStart, 0, 14, 0),
        child: Row(
          children: [
            if (lead != null) ...[lead!, const SizedBox(width: 12)],
            Expanded(child: _Name(name)),
            const SizedBox(width: 12),
            Text(value, style: AppText.section.copyWith(color: c.ink)),
          ],
        ),
      ),
    );
  }
}

/// Row with a [lead], [name] and a bar of [count] relative to [max]
class _BarRow extends StatelessWidget {
  final Widget lead;
  final String name;
  final int count;
  final int max;

  const _BarRow({
    required this.lead,
    required this.name,
    required this.count,
    required this.max,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 50),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 9, 14, 9),
        child: Row(
          children: [
            lead,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Name(name),
                  const SizedBox(height: 5),
                  ExcludeSemantics(
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: c.bg,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: max == 0
                            ? 0
                            : (count / max).clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: c.violet,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text('$count', style: AppText.section.copyWith(color: c.ink)),
          ],
        ),
      ),
    );
  }
}

class _Name extends StatelessWidget {
  final String text;

  const _Name(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: AppText.body.copyWith(
      fontSize: 15,
      height: 1.25,
      color: AppColors.of(context).ink,
    ),
  );
}

class _Rank extends StatelessWidget {
  final int place;

  const _Rank(this.place);

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minWidth: 16),
    child: Text(
      '$place',
      textAlign: TextAlign.center,
      style: AppText.section.copyWith(
        fontSize: 13,
        color: AppColors.of(context).inkSoft,
      ),
    ),
  );
}

class _GlyphTile extends StatelessWidget {
  final Color color;

  /// Color of the glyph: the tile colors are the same in both themes, except
  /// the edge one
  final Color onColor;
  final AppGlyph glyph;

  const _GlyphTile({
    required this.color,
    required this.onColor,
    required this.glyph,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: 34,
    height: 34,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(11),
    ),
    child: AppIcon(glyph, size: 20, color: onColor),
  );
}
