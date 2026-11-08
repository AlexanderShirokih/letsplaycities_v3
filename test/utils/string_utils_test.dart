import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/utils/string_utils.dart';

void main() {
  test('String.toTitleCase() converts string properly', () {
    var source = [
      'Hello dart test',
      'Hello Dart Test',
      'hello-dart test',
      'hellodarttest',
      'париж',
      'нью-йорк',
    ];
    var expected = [
      'Hello Dart Test',
      'Hello Dart Test',
      'Hello-Dart Test',
      'Hellodarttest',
      'Париж',
      'Нью-Йорк',
    ];
    expect(source.map((e) => e.toTitleCase()), equals(expected));
  });

  test('indexOfLastSuitableChar() returns correct indices', () {
    expect(indexOfLastSuitableChar('ыь'), 0);
    expect(indexOfLastSuitableChar('Тест'), equals('Тест'.lastIndexOf('т')));
    expect(indexOfLastSuitableChar('Тесть'), equals('Тесть'.lastIndexOf('т')));
    expect(indexOfLastSuitableChar('холмы'), equals('холмы'.lastIndexOf('м')));
  });

  group('formatCity()', () {
    // Player input passes through formatCity before the dictionary lookup,
    // so it must match the dictionary's spelling: lowercase, е instead of ё.
    test('trims and lowercases', () {
      expect(formatCity('  Москва \n'), 'москва');
    });

    test('replaces ё with е, including capital Ё', () {
      expect(formatCity('Орёл'), 'орел');
      expect(formatCity('ЩЁЛКОВО'), 'щелково');
    });

    test('collapses runs of dashes into one', () {
      expect(formatCity('Санкт--Петербург'), 'санкт-петербург');
      expect(formatCity('Ростов---на--Дону'), 'ростов-на-дону');
    });

    test('keeps single dashes and spaces inside the name', () {
      expect(formatCity('Нью-Йорк'), 'нью-йорк');
      expect(formatCity('Нижний Новгород'), 'нижний новгород');
    });
  });

  group('findLastSuitableChar()', () {
    // The next city must start with this letter.
    test('returns the last letter of an ordinary city', () {
      expect(findLastSuitableChar('москва'), 'а');
    });

    test('skips trailing ь, ъ and ы', () {
      expect(findLastSuitableChar('казань'), 'н');
      expect(findLastSuitableChar('холмы'), 'м');
      expect(findLastSuitableChar('тверь'), 'р');
    });

    test('returns an empty string for an empty word', () {
      expect(findLastSuitableChar(''), '');
    });
  });
}
