/// A number of seconds as whole minutes and the seconds left over.
typedef MinutesSeconds = ({int minutes, int seconds});

/// Splits [totalSeconds] into minutes and seconds, e.g. 75 into 1 minute and
/// 15 seconds.
MinutesSeconds toMinutesSeconds(int totalSeconds) =>
    (minutes: totalSeconds ~/ 60, seconds: totalSeconds.remainder(60));

/// [totalSeconds] as the clock of a move shows it, e.g. 75 as '1:15'.
String formatClock(int totalSeconds) {
  final (:minutes, :seconds) = toMinutesSeconds(totalSeconds);

  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}
