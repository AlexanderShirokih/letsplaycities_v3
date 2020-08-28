import 'package:lets_play_cities/base/game/management.dart';
import 'package:lets_play_cities/base/users.dart';

/// Repository that emits service events, like switching users
class GameServiceEventsRepository {
  final Stream<GameEvent> _eventsStream;

  GameServiceEventsRepository(this._eventsStream);

  /// Returns stream that emits events when next turn begins
  Stream<User> getUserSwitches() => _eventsStream
      .where((event) => event is OnUserSwitchedEvent)
      .cast<OnUserSwitchedEvent>()
      .map((userSwitchEvent) => userSwitchEvent.nextUser);

  /// Returns stream that emits timer ticks
  Stream<String> getTimerTicks() => _eventsStream
      .where((event) => (event) is TimeEvent)
      .cast<TimeEvent>()
      .map((event) => event.currentTime);
}
