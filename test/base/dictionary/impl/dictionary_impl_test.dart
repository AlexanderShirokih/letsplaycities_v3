import 'dart:math';

import 'package:lets_play_cities/base/dictionary.dart';
import 'package:lets_play_cities/base/dictionary/impl/dictionary_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DictionaryServiceImpl', () {
    final map = {
      'hello': CityProperties(difficulty: 0, countryCode: 1),
      'hello2': CityProperties(difficulty: 0, countryCode: 0),
      'test': CityProperties(difficulty: 0, countryCode: 2),
      'test2': CityProperties(difficulty: 0, countryCode: 3),
      'world': CityProperties(difficulty: 2, countryCode: 4),
      'world2': CityProperties(difficulty: 1, countryCode: 4),
    };

    setUp(() {
      map.forEach((key, value) {
        value.reset();
      });
    });

    test('.getAll() returns all data', () {
      expect(DictionaryServiceImpl(map).getAll(), allOf([isMap, equals(map)]));
    });

    test('.getCandidates() lists the unused cities with a country up to '
        'the difficulty', () {
      final dictionary = DictionaryServiceImpl(map);
      dictionary.markUsed('test');

      expect(dictionary.getCandidates('t', Difficulty.easy), ['test2']);
      expect(dictionary.getCandidates('h', Difficulty.hard), ['hello']);
      expect(dictionary.getCandidates('w', Difficulty.medium), ['world2']);
      expect(dictionary.getCandidates('n', Difficulty.hard), isEmpty);
    });

    group('.getRandomWordByDifficulty()', () {
      late ScriptedRandom random;
      late DictionaryServiceImpl dictionary;

      setUp(() {
        random = ScriptedRandom();
        dictionary = DictionaryServiceImpl(map, random: random);
      });

      /// Every word the call can return: the scripted [random] picks each
      /// index of the range it is asked for in turn.
      Future<Set<String>> possibleWords(
        String firstChar,
        Difficulty difficulty,
      ) async {
        random.pick = 0;
        random.ranges.clear();
        final first = await dictionary.getRandomWordByDifficulty(
          firstChar,
          difficulty,
        );
        if (random.ranges.isEmpty) return {if (first.isNotEmpty) first};

        final words = {first};
        for (var i = 1; i < random.ranges.first; i++) {
          random.pick = i;
          words.add(
            await dictionary.getRandomWordByDifficulty(firstChar, difficulty),
          );
        }
        return words;
      }

      test('picks among the cities starting with the given letter', () async {
        expect(await possibleWords('t', Difficulty.easy), {'test', 'test2'});
      });

      test('gives every eligible city the same chance', () async {
        // One draw over exactly the eligible cities: test, test2.
        await dictionary.getRandomWordByDifficulty('t', Difficulty.easy);
        expect(random.ranges, [2]);
      });

      test('never picks a city without a country', () async {
        expect(await possibleWords('h', Difficulty.hard), {'hello'});
      });

      test('picks cities up to the chosen difficulty', () async {
        expect(await possibleWords('w', Difficulty.easy), isEmpty);
        expect(await possibleWords('w', Difficulty.medium), {'world2'});
        expect(await possibleWords('w', Difficulty.hard), {'world', 'world2'});
      });

      test('never picks a used city until the dictionary is reset', () async {
        dictionary.markUsed('test');
        expect(await possibleWords('t', Difficulty.easy), {'test2'});

        dictionary.reset();
        expect(await possibleWords('t', Difficulty.easy), {'test', 'test2'});
      });

      test('with no first letter picks from every eligible city', () async {
        // The first move of a game has no letter to continue from.
        expect(await possibleWords('', Difficulty.easy), {
          'hello',
          'test',
          'test2',
        });
      });

      test('returns an empty string when no city is left', () async {
        dictionary.markUsed('test');
        dictionary.markUsed('test2');

        expect(
          await dictionary.getRandomWordByDifficulty('t', Difficulty.hard),
          isEmpty,
        );
        expect(
          await dictionary.getRandomWordByDifficulty('n', Difficulty.hard),
          isEmpty,
        );
        expect(random.ranges, isEmpty);
      });
    });

    group('.getCountryCode()', () {
      test('returns `0` if there is no word', () {
        expect(
          DictionaryServiceImpl(map).getCountryCode('invalid word'),
          isZero,
        );
      });

      test('matches with actual country code value when present', () {
        expect(DictionaryServiceImpl(map).getCountryCode('test2'), equals(3));
      });
    });

    group('.markUsed()', () {
      test('marks word', () {
        final d = DictionaryServiceImpl(map);
        d.reset();
        expect(d.getAll()['test']!.used, isFalse);
        d.markUsed('test');
        expect(d.getAll()['test']!.used, isTrue);
        d.markUsed('test');
        expect(d.getAll()['test']!.used, isTrue);
      });

      test('does nothing when there is no word', () {
        final d = DictionaryServiceImpl(map);
        expect(() => d.markUsed('invalid word'), returnsNormally);
      });
    });

    test('.clear() clears map data', () {
      final d = DictionaryServiceImpl(Map.of(map));
      d.clear();
      expect(d.getAll(), isEmpty);
    });

    test('.reset() resets usage flags', () {
      final d = DictionaryServiceImpl(map);
      d.markUsed('test');
      d.reset();
      expect(d.getAll()['test']!.used, isFalse);
    });

    group('.checkCity()', () {
      test('returns [OK] when word was not used before', () async {
        final d = DictionaryServiceImpl(map);
        expect(d.getAll()['test']!.used, isFalse);
        expect(await d.checkCity('test'), equals(CityResult.ok));
      });

      test('returns [CITY_NOT_FOUND] when word really not found', () async {
        expect(
          await DictionaryServiceImpl(map).checkCity('invalid'),
          equals(CityResult.cityNotFound),
        );
      });

      test('returns [ALREADY_USED] when word was used', () async {
        final d = DictionaryServiceImpl(map);
        d.markUsed('test');
        expect(await d.checkCity('test'), equals(CityResult.alreadyUsed));
      });
    });
  });

  group('DictionaryServiceImpl.getCorrectionVariants()', () {
    DictionaryServiceImpl dictionaryOf(List<String> cities) =>
        DictionaryServiceImpl({
          for (final city in cities)
            city: CityProperties(difficulty: 0, countryCode: 1),
        });

    final dictionary = dictionaryOf(['москва', 'лондон', 'тула', 'уфа']);

    setUp(dictionary.reset);

    Future<List<String>> correct(String word) =>
        dictionary.getCorrectionVariants(word).toList();

    test('suggests the city for a single typo of any kind', () async {
      expect(await correct('масква'), ['москва'], reason: 'wrong letter');
      expect(await correct('мосва'), ['москва'], reason: 'missing letter');
      expect(await correct('москвап'), ['москва'], reason: 'extra letter');
      expect(await correct('мсоква'), ['москва'], reason: 'swapped letters');
    });

    test('suggests the city for two typos', () async {
      // Both orders of fixing the typos lead to the same city; it is
      // offered once.
      expect(await correct('маскба'), ['москва']);
    });

    test('never changes the first letter', () async {
      // The player must name a city on the required letter, so 'нондон'
      // is not corrected to 'лондон'.
      expect(await correct('нондон'), isEmpty);
    });

    test('never suggests a used city', () async {
      dictionary.markUsed('москва');
      expect(await correct('масква'), isEmpty);
    });

    test('never suggests a city of three letters or fewer', () async {
      expect(await correct('уфаа'), isEmpty);
    });

    test('completes with no suggestions when nothing is close', () async {
      // DatabaseChecker waits for the stream to end before it reports the
      // word as not found.
      await expectLater(dictionary.getCorrectionVariants('абвгде'), emitsDone);
    });

    test('suggests at most three cities one typo away', () async {
      const close = ['тага', 'тапа', 'тара', 'таха'];
      final suggestions = await dictionaryOf(close)
          .getCorrectionVariants('тава')
          .toList();

      expect(suggestions, hasLength(3));
      expect(suggestions, everyElement(isIn(close)));
      expect(suggestions.toSet(), hasLength(3));
    });

    test('a doubled letter does not use up a suggestion slot', () async {
      // Dropping either 'л' of 'тулла' gives 'тула'. That counted as two of
      // the three suggestions, so 'тулма' was never offered.
      final suggestions = await dictionaryOf(['тула', 'тулга', 'тулма'])
          .getCorrectionVariants('тулла')
          .toList();

      expect(suggestions, unorderedEquals(['тула', 'тулга', 'тулма']));
    });

    test('suggests two-typo cities only when none is one typo away', () async {
      final suggestions = await dictionaryOf(['москва', 'маскбо'])
          .getCorrectionVariants('масква')
          .toList();

      expect(suggestions, ['москва']);
    });

    test('suggests at most four cities two typos away', () async {
      const twoAway = ['аббаа', 'абаба', 'абааб', 'аабба', 'аабаб'];
      final suggestions = await dictionaryOf(twoAway)
          .getCorrectionVariants('ааааа')
          .toList();

      expect(suggestions, hasLength(4));
      expect(suggestions, everyElement(isIn(twoAway)));
      expect(suggestions.toSet(), hasLength(4));
    });
  });
}

/// Returns [pick] from [nextInt] and records the ranges it was asked for.
class ScriptedRandom implements Random {
  int pick = 0;
  final ranges = <int>[];

  @override
  int nextInt(int max) {
    ranges.add(max);
    return pick;
  }

  @override
  bool nextBool() => throw UnimplementedError();

  @override
  double nextDouble() => throw UnimplementedError();
}
