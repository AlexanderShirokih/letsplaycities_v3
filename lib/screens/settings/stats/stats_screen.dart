import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'package:lets_play_cities/base/repositories/cities/country_repository.dart';
import 'package:lets_play_cities/base/scoring.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
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
      appBar: AppBar(title: Text(t.stats.title)),
      body: FutureBuilder<Map<String, String>>(
        future: _countryNames,
        builder: (context, names) =>
            _StatisticsList(t, scoringSet, names.data ?? const {}),
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
    children: _scoringSet.groups
        .map((group) => _createCard(context, group))
        .toList(),
  );

  Widget _createCard(BuildContext context, ScoringGroup group) => Card(
    elevation: 5.0,
    margin: const EdgeInsets.all(8.0),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 12.0, 20.0, 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            textBaseline: TextBaseline.alphabetic,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _t.stats.groups[group.main.name]!,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (group.main.asString() != null)
                Text(
                  group.main.asString() ?? '...',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
            ],
          ),
          const Divider(height: 10.0, thickness: 2.0),
          group.child.any((element) => element.hasValue())
              ? Column(
                  children: group.child
                      .map((field) => _buildFieldsList(group, field))
                      .toList(),
                )
              : Text(_t.stats.noData),
        ],
      ),
    ),
  );

  Widget _buildFieldsList(ScoringGroup group, ScoringField field) {
    final pair = field.asPairedString();
    final name = group.main.name == groupCountries
        ? _countryNames[pair.name] ?? pair.name
        : _t.stats.fields[pair.name] ?? pair.name.toTitleCase();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(name), Text(pair.value ?? '--')],
      ),
    );
  }
}
