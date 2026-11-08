import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/dictionary/impl/country_list_loader_factory.dart';
import 'package:lets_play_cities/base/dictionary/impl/dictionary_factory.dart';

import 'dictionary_test_files.dart';

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
        lines.every(
          (l) => !l.contains('|')
              ? false
              : _validateSampleLine(l.split(RegExp(r'\||\+'))),
        ),
        isTrue,
      );
    });

    test('data loads correctly', () async {
      final list = await CountryListLoaderServiceFactory()
          .createCountryList()
          .loadCountryList();

      expect(list, isNotEmpty);
      expect(list.first.countryCode, equals(91));
      expect(list.skip(5).first.hasSiblingCity, isTrue);
    });

    group('bundled list', () {
      late Directory supportDir;

      setUp(() async {
        supportDir = await Directory.systemTemp.createTemp('country_list');
        fakeApplicationSupportDirectory(supportDir);
        DictionaryFactory.invalidateCache();
      });

      tearDown(() async {
        DictionaryFactory.invalidateCache();
        fakeApplicationSupportDirectory(null);
        await supportDir.delete(recursive: true);
      });

      test('has every country of the embedded dictionary', () async {
        final countries = await CountryListLoaderServiceFactory()
            .createCountryList()
            .loadCountryList();
        final dictionary = await DictionaryFactory().createDictionary();

        final listed = countries.map((c) => c.countryCode).toSet();
        final unlisted = {
          for (final entry in dictionary.getAll().entries)
            if (!listed.contains(entry.value.countryCode))
              entry.key: entry.value.countryCode,
        };

        expect(unlisted, isEmpty);
      });

      test('has no duplicate country names', () async {
        final names =
            (await CountryListLoaderServiceFactory()
                    .createCountryList()
                    .loadCountryList())
                .map((c) => c.name)
                .toList();

        expect(names.toSet(), hasLength(names.length));
      });

      test('keeps the city Палестина playable', () async {
        // 'палестина' is also a city (in Колумбия): without the '+' marker
        // the game would reject it as a country name.
        final countries = await CountryListLoaderServiceFactory()
            .createCountryList()
            .loadCountryList();

        expect(
          countries.singleWhere((c) => c.name == 'Палестина').hasSiblingCity,
          isTrue,
        );
      });
    });
  });
}

bool _validateSampleLine(List<String> split) =>
    split[0].isNotEmpty && RegExp('[0-9]+').allMatches(split[1]).isNotEmpty;
