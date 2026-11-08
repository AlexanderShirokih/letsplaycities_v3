import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/dictionary.dart';
import 'package:lets_play_cities/base/dictionary/country_entity.dart';
import 'package:lets_play_cities/base/dictionary/exclusion_messages.dart';
import 'package:lets_play_cities/base/dictionary/impl/exclusions_impl.dart';

/// Each message names its code and lists its arguments, so the result shows
/// which one was used and what it was given.
class _CodeNamingMessages implements ExclusionMessages {
  @override
  String thisIsACountry(String city) => 'THIS_IS_A_COUNTRY:$city';

  @override
  String thisIsAState(String city) => 'THIS_IS_A_STATE:$city';

  @override
  String thisIsNotACity(String city) => 'THIS_IS_NOT_A_CITY:$city';

  @override
  String renamedCity(String city, String newName) =>
      'RENAMED_CITY:$city,$newName';

  @override
  String incompleteCity(String city) => 'INCOMPLETE_CITY:$city';

  @override
  String notACity(String city, String kind) => 'NOT_A_CITY:$city,$kind';
}

void main() {
  group('ExclusionsServiceImpl()', () {
    late ExclusionsService exclusion;

    setUp(() {
      exclusion = ExclusionsServiceImpl(
        exclusionsList: _createExclusionMap(),
        countries: [
          CountryEntity('aabr', 1, false),
          CountryEntity('creade', 2, false),
          CountryEntity('denito', 3, false),
        ],
        states: ['statea', 'stateb'],
        messages: _CodeNamingMessages(),
      );
    });

    group('.checkForExclusion()', () {
      test('with country returns an exclusion', () {
        expect(
          exclusion.checkForExclusion('creade'),
          equals('THIS_IS_A_COUNTRY:Creade'),
        );
      });

      test('with state returns an exclusion', () {
        expect('THIS_IS_A_STATE:Stateb', exclusion.checkForExclusion('stateb'));
      });

      test('by all types returns an exclusion', () {
        expect(
          exclusion.checkForExclusion('bcde'),
          equals('RENAMED_CITY:Bcde,Renamed'),
        );
        expect(
          exclusion.checkForExclusion('cdef'),
          equals('INCOMPLETE_CITY:Incomplete'),
        );
        expect(
          exclusion.checkForExclusion('efgh'),
          equals('NOT_A_CITY:Efgh,not a city'),
        );
        expect(
          exclusion.checkForExclusion('defg'),
          equals('THIS_IS_NOT_A_CITY:Defg'),
        );
      });

      test('for alternative name returns empty string', () {
        expect(exclusion.checkForExclusion('abcd'), isEmpty);
      });

      test('with normal word returns empty string', () {
        expect(exclusion.checkForExclusion('normal'), isEmpty);
      });
    });

    test(
      'getAlternativeName() returns alternative name or null if not exists',
      () {
        expect(exclusion.getAlternativeName('abcd'), equals('alter'));
        expect(exclusion.getAlternativeName('bcde'), isNull);
      },
    );

    group('.hasNoExclusion()', () {
      test('normal word has no exclusions', () {
        expect(exclusion.hasNoExclusions('normal'), isTrue);
      });

      test('returns word with any case', () {
        expect(exclusion.hasNoExclusions('AbCd'), isFalse);
      });

      test('returns false for all the other types', () {
        expect(exclusion.hasNoExclusions('creade'), isFalse);
        expect(exclusion.hasNoExclusions('stateb'), isFalse);
        expect(exclusion.hasNoExclusions('bcde'), isFalse);
      });
    });
  });
}

Map<String, Exclusion> _createExclusionMap() => {
  'abcd': Exclusion(ExclusionType.alternativeName, 'alter'),
  'bcde': Exclusion(ExclusionType.cityWasRenamed, 'renamed'),
  'cdef': Exclusion(ExclusionType.incompleteName, 'incomplete'),
  'defg': Exclusion(ExclusionType.regionName, 'region'),
  'efgh': Exclusion(ExclusionType.notACity, 'not a city'),
};
