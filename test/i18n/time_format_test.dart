import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/i18n/time_format.dart';

void main() {
  final t = AppLocale.ru.buildSync();

  // Used for the move timer and for battle durations, both in seconds.
  group('formatMinutesSeconds()', () {
    test('shows only seconds below a minute', () {
      expect(formatMinutesSeconds(t, 0), '0сек');
      expect(formatMinutesSeconds(t, 59), '59сек');
    });

    test('shows minutes and seconds from one minute up', () {
      expect(formatMinutesSeconds(t, 60), '1мин 0сек');
      expect(formatMinutesSeconds(t, 75), '1мин 15сек');
    });

    test('does not roll minutes over into hours', () {
      expect(formatMinutesSeconds(t, 3600), '60мин 0сек');
    });
  });
}
