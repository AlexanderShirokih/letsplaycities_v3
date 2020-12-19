import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lets_play_cities/base/scoring.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/screens/common/utils.dart';
import 'package:lets_play_cities/utils/string_utils.dart';

class StatisticsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) => buildWithLocalization(
        context,
        (l10n) => Scaffold(
          appBar: AppBar(
            title: Text(l10n.stats['title']),
          ),
          body: _StatisticsList(
            l10n.stats,
            _getOrCreate(context.watch<GamePreferences>()),
          ),
        ),
      );

  ScoringSet _getOrCreate(GamePreferences prefs) {
    final data = prefs.scoringData;
    return data.isEmpty
        ? ScoringSet.initial()
        : ScoringSet.fromJson(jsonDecode(data));
  }
}

class _StatisticsList extends StatelessWidget {
  final Map<String, dynamic> _l10n;
  final ScoringSet _scoringSet;

  const _StatisticsList(this._l10n, this._scoringSet);

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
                    _l10n['groups'][group.main.name],
                    style: Theme.of(context).textTheme.headline6,
                  ),
                  if (group.main.asString() != null)
                    Text(
                      group.main.asString(),
                      style: Theme.of(context).textTheme.headline6,
                    )
                ],
              ),
              const Divider(
                height: 10.0,
                thickness: 2.0,
              ),
              group.child.any((element) => element.hasValue())
                  ? Column(
                      children: group.child
                          .map((field) => _buildFieldsList(field))
                          .toList(),
                    )
                  : Text(_l10n['no_data']),
            ],
          ),
        ),
      );

  Widget _buildFieldsList(ScoringField field) {
    final pair = field.asPairedString();
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(_l10n['fields'][pair.name] ?? pair.name.toTitleCase()),
          Text(pair.value ?? '--'),
        ],
      ),
    );
  }
}
