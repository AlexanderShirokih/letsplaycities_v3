import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/utils/minutes_seconds.dart';

/// Formats [totalSeconds] as the game timer and the game history show it:
/// '1мин 15сек', or '15сек' under a minute.
String formatMinutesSeconds(Translations t, int totalSeconds) {
  final (:minutes, :seconds) = toMinutesSeconds(totalSeconds);
  return minutes > 0
      ? t.time.minutesSeconds(minutes: minutes, seconds: seconds)
      : t.time.seconds(seconds: seconds);
}
