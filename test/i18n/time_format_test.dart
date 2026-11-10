import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/i18n/time_format.dart';

void main() {
  final t = AppLocale.ru.buildSync();

  // Used for the move timer and for battle durations, both in seconds.
  group('formatMinutesSeconds()', () {
    test('shows only seconds below a minute', () {
      expect(formatMinutesSeconds(t, 0), '0 с');
      expect(formatMinutesSeconds(t, 59), '59 с');
    });

    test('shows minutes and seconds from one minute up', () {
      expect(formatMinutesSeconds(t, 60), '1 мин 0 с');
      expect(formatMinutesSeconds(t, 75), '1 мин 15 с');
    });

    test('does not roll minutes over into hours', () {
      expect(formatMinutesSeconds(t, 3600), '60 мин 0 с');
    });
  });
}
