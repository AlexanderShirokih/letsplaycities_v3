import 'package:intl/intl.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/utils/online_window.dart';

final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');
final DateFormat _timeFormat = DateFormat('HH:mm');

/// Days after which the date replaces "N days ago"
const _daysAgoLimit = 30;

/// Describes when a user was last online, as seen at [now], without the
/// gender of the user: "в сети" within five minutes, the time for
/// today, "yesterday", "N days ago" and the date for the older visits.
String formatLastSeen(Translations t, DateTime lastSeen, DateTime now) {
  final text = t.online.lastSeen;
  if (now.difference(lastSeen) < userOnlineWindow) return text.now;

  // Compares calendar dates; UTC keeps a daylight saving change from making
  // a day shorter than 24 hours.
  final daysAgo = DateTime.utc(now.year, now.month, now.day)
      .difference(DateTime.utc(lastSeen.year, lastSeen.month, lastSeen.day))
      .inDays;

  if (daysAgo <= 0) return text.today(time: _timeFormat.format(lastSeen));
  if (daysAgo == 1) return text.yesterday;
  if (daysAgo <= _daysAgoLimit) return text.daysAgo(count: daysAgo);

  return text.date(date: _dateFormat.format(lastSeen));
}
