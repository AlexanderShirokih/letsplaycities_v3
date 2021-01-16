import 'package:lets_play_cities/base/dictionary.dart';
import 'package:lets_play_cities/base/dictionary/impl/dictionary_impl.dart';
import 'package:test/test.dart';

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

    group('.getRandomWord()', () {
      test('returns word starting at specified char', () async {
        expect(
            await DictionaryServiceImpl(map)
                .getRandomWordByDifficulty('t', Difficulty.EASY),
            anyOf(['test', 'test2']));
      });

      test('filters by difficulty', () async {
        expect(
            await DictionaryServiceImpl(map)
                .getRandomWordByDifficulty('w', Difficulty.MEDIUM),
            equals('world2'));
      });

      test('returns empty string if no words starting at char', () async {
        expect(
            await DictionaryServiceImpl(map)
                .getRandomWordByDifficulty('n', Difficulty.MEDIUM),
            anyOf([returnsNormally, isEmpty]));
      });

      test('can return the same word twice', () async {
        for (var i = 0; i < 10; i++) {
          expect(
              await DictionaryServiceImpl(map)
                  .getRandomWordByDifficulty('w', Difficulty.MEDIUM),
              anyOf([returnsNormally, equals('world2')]));
        }
      });

      test('not uses words city countryCode==0', () async {
        for (var i = 0; i < 10; i++) {
          expect(
              await DictionaryServiceImpl(map)
                  .getRandomWordByDifficulty('h', Difficulty.EASY),
              isNot(equals('hello2')));
        }
      });

      test('not uses already used words', () async {
        final d = DictionaryServiceImpl(map);
        d.markUsed('test');

        for (var i = 0; i < 10; i++) {
          expect(await d.getRandomWordByDifficulty('t', Difficulty.EASY),
              isNot(equals('test')));
        }
      });
    });

    group('.getCountryCode()', () {
      test('returns `0` if there is no word', () {
        expect(
            DictionaryServiceImpl(map).getCountryCode('invalid word'), isZero);
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
        expect(await d.checkCity('test'), equals(CityResult.OK));
      });

      test('returns [CITY_NOT_FOUND] when word really not found', () async {
        expect(await DictionaryServiceImpl(map).checkCity('invalid'),
            equals(CityResult.CITY_NOT_FOUND));
      });

      test('returns [ALREADY_USED] when word was used', () async {
        final d = DictionaryServiceImpl(map);
        d.markUsed('test');
        expect(await d.checkCity('test'), equals(CityResult.ALREADY_USED));
      });
    });
  });
}
