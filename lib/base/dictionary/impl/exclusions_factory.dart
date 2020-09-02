import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:lets_play_cities/base/dictionary/impl/exclusions_impl.dart';
import 'package:lets_play_cities/base/dictionary/country_entity.dart';
import 'package:lets_play_cities/base/dictionary.dart';
import 'package:lets_play_cities/l18n/localizations_keys.dart';

import '../country_list_loader.dart';

class ExclusionsFactory {
  static const _OTHERS_LIST_NAME = "assets/data/others.txt";
  static const _STATES_LIST_NAME = "assets/data/states.txt";

  final CountryListLoaderService countryListLoaderService;
  final Map<ErrorCode, String> errMessages;

  ExclusionsFactory(this.countryListLoaderService, this.errMessages);

  Future<ExclusionsService> createExclusions() async {
    final exclusionsList = Map<String, Exclusion>();

    await rootBundle
        .loadString(_OTHERS_LIST_NAME)
        .asStream()
        .expand((string) => LineSplitter().convert(string))
        .where((line) => line.isNotEmpty)
        .map((line) => line.split('|'))
        .listen((split) {
      exclusionsList[split[0]] =
          Exclusion(ExclusionType.values[int.parse(split[1])], split[2]);
    }).asFuture();

    final List<String> states = await rootBundle
        .loadString(_STATES_LIST_NAME)
        .asStream()
        .expand((string) => LineSplitter().convert(string))
        .toList();

    final List<CountryEntity> countries =
        await countryListLoaderService.loadCountryList();

    return ExclusionsServiceImpl(
        exclusionsList: exclusionsList,
        errMessages: errMessages,
        countries: countries,
        states: states);
  }
}
