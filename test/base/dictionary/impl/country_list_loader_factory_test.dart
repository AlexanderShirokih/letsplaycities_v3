import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/dictionary/impl/country_list_loader_factory.dart';

void main() {
  group('CountryListLoaderFactory', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    test('sample data is valid', () async {
      final lines = await rootBundle
          .loadString('assets/data/countries.txt')
          .asStream()
          .expand((element) => LineSplitter().convert(element))
          .where((line) => line.isNotEmpty)
          .toList();

      expect(
          lines.every((l) => !l.contains('|')
              ? false
              : _validateSampleLine(l.split(RegExp(r'\||\+')))),
          isTrue);
    });

    test('data loads correctly', () async {
      final list = await CountryListLoaderServiceFactory()
          .createCountryList()
          .loadCountryList();

      expect(list, isNotEmpty);
      expect(list.first.countryCode, equals(91));
      expect(list.skip(5).first.hasSiblingCity, isTrue);
    });
  });
}

bool _validateSampleLine(List<String> split) =>
    split[0].isNotEmpty && RegExp('[0-9]+').allMatches(split[1]).isNotEmpty;
