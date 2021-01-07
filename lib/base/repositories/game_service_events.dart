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

  /// Returns stream that emits timer ticks
  Stream<String> getTimerTicks() => _eventsStream
      .where((event) => (event) is TimeEvent)
      .cast<TimeEvent>()
      .map((event) => event.currentTime);
}
