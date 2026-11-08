import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';

void main() {
  final t = AppLocale.ru.buildSync();

  test('wordsCount() uses the Russian plural forms', () {
    const expected = {
      0: '0 слов',
      1: '1 слово',
      2: '2 слова',
      5: '5 слов',
      11: '11 слов',
      21: '21 слово',
      22: '22 слова',
      25: '25 слов',
      111: '111 слов',
    };

    expect(
      expected.map(
        (count, _) => MapEntry(count, t.online.wordsCount(count: count)),
      ),
      expected,
    );
  });
}
