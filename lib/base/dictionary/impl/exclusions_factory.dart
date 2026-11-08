import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:lets_play_cities/base/dictionary.dart';
import 'package:lets_play_cities/base/dictionary/exclusion_messages.dart';
import 'package:lets_play_cities/base/dictionary/impl/exclusions_impl.dart';

import '../country_list_loader.dart';

class ExclusionsFactory {
  static const _othersListName = 'assets/data/others.txt';
  static const _statesListName = 'assets/data/states.txt';

  final CountryListLoaderService countryListLoaderService;
  final ExclusionMessages messages;

  ExclusionsFactory(this.countryListLoaderService, this.messages);

  Future<ExclusionsService> createExclusions() async {
    final exclusionsList = <String, Exclusion>{};

    await rootBundle
        .loadString(_othersListName)
        .asStream()
        .expand((string) => LineSplitter().convert(string))
        .where((line) => line.isNotEmpty)
        .map((line) => line.split('|'))
        .listen((split) {
          exclusionsList[split[0]] = Exclusion(
            ExclusionType.values[int.parse(split[1])],
            split[2],
          );
        })
        .asFuture();

    final states = await rootBundle
        .loadString(_statesListName)
        .asStream()
        .expand((string) => LineSplitter().convert(string))
        .toList();

    final countries = await countryListLoaderService.loadCountryList();

    return ExclusionsServiceImpl(
      exclusionsList: exclusionsList,
      messages: messages,
      countries: countries,
      states: states,
    );
  }
}
