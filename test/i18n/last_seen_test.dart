import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/i18n/last_seen.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';

void main() {
  final t = AppLocale.ru.buildSync();
  final now = DateTime(2026, 3, 10, 12, 0);

  String seen(DateTime lastSeen) => formatLastSeen(t, lastSeen, now);

  test('within five minutes the user is online', () {
    expect(seen(now.subtract(const Duration(minutes: 4))), 'в сети');
    expect(seen(now), 'в сети');
  });

  test('earlier today shows the time', () {
    expect(seen(DateTime(2026, 3, 10, 9, 5)), 'в сети в 09:05');
  });

  test('yesterday has no gender', () {
    expect(seen(DateTime(2026, 3, 9, 23, 50)), 'в сети вчера');
  });

  test('days ago are plural', () {
    expect(seen(DateTime(2026, 3, 9 - 2, 8)), 'в сети 3 дня назад');
    expect(seen(DateTime(2026, 3, 5, 8)), 'в сети 5 дней назад');
    expect(seen(DateTime(2026, 2, 9, 8)), 'в сети 29 дней назад');
  });

  test('a month ago shows the date', () {
    expect(seen(DateTime(2026, 1, 7, 8)), 'в сети 07.01.2026');
  });

  test('yesterday of another month counts as yesterday', () {
    expect(
      formatLastSeen(
        t,
        DateTime(2026, 2, 28, 23, 50),
        DateTime(2026, 3, 1, 0, 10),
      ),
      'в сети вчера',
    );
  });
}
