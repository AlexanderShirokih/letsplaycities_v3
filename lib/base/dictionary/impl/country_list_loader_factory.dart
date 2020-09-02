import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:lets_play_cities/base/dictionary/country_entity.dart';

import '../country_list_loader.dart';

/// Implementation of [CountryListLoaderService] that loads country list from
/// file as '|'-separated values.
class CountryListLoaderServiceFactory {
  static const _COUNTRIES_LIST_NAME = "assets/data/countries.txt";

  CountryListLoaderService createCountryList() =>
      _CountryListLoaderServiceImpl(_COUNTRIES_LIST_NAME);
}

class _CountryListLoaderServiceImpl extends CountryListLoaderService {
  final String _path;

  _CountryListLoaderServiceImpl(this._path);

  /// Loads country list from storage.
  @override
  Future<List<CountryEntity>> loadCountryList() {
    return rootBundle
        .loadString(_path)
        .asStream()
        .expand((string) => LineSplitter().convert(string))
        .where((line) => line.isNotEmpty)
        .map((line) => line.split(RegExp(r'\||\+')))
        .map((split) =>
            CountryEntity(split[0], int.parse(split[1]), split.length == 3))
        .toList();
  }
}
