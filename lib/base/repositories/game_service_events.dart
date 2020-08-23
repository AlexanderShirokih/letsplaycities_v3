import 'package:lets_play_cities/base/management.dart';
import 'package:lets_play_cities/base/users.dart';
import 'package:lets_play_cities/base/game_session.dart';

/// Repository that emits service events, like switching users
class GameServiceEventsRepository {
  final GameSession _session;

  GameServiceEventsRepository(this._session);

  Stream<ControlEvent> _filterControlEvents() => _session.eventChannel
      .getInputEvents()
      .where((event) => event is ControlEvent)
      .cast<ControlEvent>();

  /// Returns stream that emits events when next turn begins
  Stream<User> getUserSwitches() => _filterControlEvents()
      .where((event) => event is OnUserSwitchedEvent)
      .cast<OnUserSwitchedEvent>()
      .map((userSwitchEvent) => _session.getUserById(userSwitchEvent.userId));

  /// Returns stream that emits timer ticks
  Stream<String> getTimerTicks() => _filterControlEvents()
      .where((event) => (event) is TimeEvent)
      .cast<TimeEvent>()
      .map((event) => event.currentTime);
}
