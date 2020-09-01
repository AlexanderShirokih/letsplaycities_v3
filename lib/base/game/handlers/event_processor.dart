import 'dart:async';

import 'package:lets_play_cities/base/game/management.dart';

/// Intercepts events from [EventsChannel].
abstract class EventHandler {
  /// Invoked on every input [event]s that comes from previous [EventHandler]s.
  /// Should emit events that will pass to the next processing stages.
  Stream<GameEvent> process(GameEvent event);
}

/// Filters event only of type [T] and processes it on [processEvent](T).
abstract class TypedEventHandler<T extends GameEvent> extends EventHandler {
  @override
  Stream<GameEvent> process(GameEvent event) {
    return event is T ? processTypedEvent(event) : Stream.value(event);
  }

  /// Invoked on input event of type T that comes from previous [EventHandler]s.
  /// Should emit events that will pass to the next processing stages.
  Stream<GameEvent> processTypedEvent(T event);
}
