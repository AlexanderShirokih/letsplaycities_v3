import 'package:lets_play_cities/base/game/management.dart';

/// Repository that emits service events, like switching users
class GameServiceEventsRepository {
  final Stream<GameEvent> _eventsStream;

  GameServiceEventsRepository(this._eventsStream);

  /// Returns stream of map where key is user instance and value is a flag which
  /// is `true` when the user is the next. Emits events when next turn begins.
  Stream<OnUserSwitchedEvent> getUserSwitches() => _eventsStream
      .where((event) => event is OnUserSwitchedEvent)
      .cast<OnUserSwitchedEvent>();

  /// Returns stream that emits the seconds left for the move on every
  /// timer tick
  Stream<int> getTimerTicks() => _eventsStream
      .where((event) => event is TimeEvent)
      .cast<TimeEvent>()
      .map((event) => event.secondsLeft);

  /// Returns stream that emits the first letter of every move; an empty
  /// string means any letter.
  Stream<String> getFirstChars() => _eventsStream
      .where((event) => event is OnFirstCharChanged)
      .cast<OnFirstCharChanged>()
      .map((event) => event.firstChar);
}
