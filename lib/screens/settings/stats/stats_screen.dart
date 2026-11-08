import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'package:lets_play_cities/base/repositories/cities/country_repository.dart';
import 'package:lets_play_cities/base/scoring.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/common/d2/d2.dart';
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
      backgroundColor: D2Colors.of(context).bg,
      body: SafeArea(
        child: Column(
          children: [
            D2ScreenHeader(
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

class _StatisticsList extends StatelessWidget {
  final Translations _t;
  final ScoringSet _scoringSet;
  final Map<String, String> _countryNames;

  const _StatisticsList(this._t, this._scoringSet, this._countryNames);

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
    children: [
      for (final group in _scoringSet.groups) ...[
        _createCard(context, group),
        const SizedBox(height: 12),
      ],
    ],
  );

  Widget _createCard(BuildContext context, ScoringGroup group) {
    final c = D2Colors.of(context);

    return D2Card(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            textBaseline: TextBaseline.alphabetic,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _t.stats.groups[group.main.name]!,
                  style: D2Text.section.copyWith(color: c.ink),
                ),
              ),
              if (group.main.asString() != null) ...[
                const SizedBox(width: 12.0),
                Text(
                  group.main.asString() ?? '...',
                  style: D2Text.section.copyWith(color: c.ink),
                ),
              ],
            ],
          ),
          Container(
            height: 2.0,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            color: c.bg,
          ),
          group.child.any((element) => element.hasValue())
              ? Column(
                  children: group.child
                      .map((field) => _buildFieldsList(c, group, field))
                      .toList(),
                )
              : Text(
                  _t.stats.noData,
                  style: D2Text.bodyRegular.copyWith(color: c.inkSoft),
                ),
        ],
      ),
    );
  }

  Widget _buildFieldsList(D2Colors c, ScoringGroup group, ScoringField field) {
    final pair = field.asPairedString();
    final name = group.main.name == groupCountries
        ? _countryNames[pair.name] ?? pair.name
        : _t.stats.fields[pair.name] ?? pair.name.toTitleCase();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(name, style: D2Text.bodyRegular.copyWith(color: c.ink)),
          ),
          const SizedBox(width: 12.0),
          Text(pair.value ?? '--', style: D2Text.body.copyWith(color: c.ink)),
        ],
      ),
    );
  }
}
