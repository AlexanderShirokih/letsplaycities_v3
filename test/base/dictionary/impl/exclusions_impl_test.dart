import 'package:lets_play_cities/base/dictionary.dart';
import 'package:lets_play_cities/base/dictionary/country_entity.dart';
import 'package:lets_play_cities/base/dictionary/impl/exclusions_impl.dart';
import 'package:lets_play_cities/l18n/localizations_keys.dart';
import 'package:test/test.dart';

void main() {
  group('ExclusionsServiceImpl()', () {
    ExclusionsService exclusion;

    setUp(() {
      exclusion = ExclusionsServiceImpl(
          exclusionsList: _createExclusionMap(),
          countries: [
            CountryEntity('aabr', 1, false),
            CountryEntity('creade', 2, false),
            CountryEntity('denito', 3, false)
          ],
          states: ['statea', 'stateb'],
          errMessages: ErrorCode.values.asMap().map((_, errCode) =>
              MapEntry(errCode, '${errCode.toString().split('.').last}:%1\$')));
    });

    group('.checkForExclusion()', () {
      test('with country returns an exclusion', () {
        expect(exclusion.checkForExclusion('creade'),
            equals('THIS_IS_A_COUNTRY:Creade'));
      });

      test('with state returns an exclusion', () {
        expect('THIS_IS_A_STATE:Stateb', exclusion.checkForExclusion('stateb'));
      });

      test('by all types returns an exclusion', () {
        expect(
            exclusion.checkForExclusion('bcde'), equals('RENAMED_CITY:Bcde'));
        expect(exclusion.checkForExclusion('cdef'),
            equals('INCOMPLETE_CITY:Incomplete'));
        expect(exclusion.checkForExclusion('efgh'), equals('NOT_A_CITY:Efgh'));
        expect(exclusion.checkForExclusion('defg'),
            equals('THIS_IS_NOT_A_CITY:Defg'));
      });

      test('for alternative name returns empty string', () {
        expect(exclusion.checkForExclusion('abcd'), isEmpty);
      });

      test('with normal word returns empty string', () {
        expect(exclusion.checkForExclusion('normal'), isEmpty);
      });
    });

    test('getAlternativeName() returns alternative name or null if not exists',
        () {
      expect(exclusion.getAlternativeName('abcd'), equals('alter'));
      expect(exclusion.getAlternativeName('bcde'), isNull);
    });

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
      'abcd': Exclusion(ExclusionType.ALTERNATIVE_NAME, 'alter'),
      'bcde': Exclusion(ExclusionType.CITY_WAS_RENAMED, 'renamed'),
      'cdef': Exclusion(ExclusionType.INCOMPLETE_NAME, 'incomplete'),
      'defg': Exclusion(ExclusionType.REGION_NAME, 'region'),
      'efgh': Exclusion(ExclusionType.NOT_A_CITY, 'not a city')
    };
