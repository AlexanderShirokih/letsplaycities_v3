import 'dart:async';

import 'package:lets_play_cities/base/game/handlers.dart';

import 'game_events.dart';

/// Pipeline system for dispatching events.
abstract class AbstractEventChannel {
  /// Sends input event for processing and returns [Stream] with processing result.
  /// [RawWordEvent]s should be converted to any of [WordCheckingResult] type.
  Stream<GameEvent> sendEvent(GameEvent event);

}

/// Dispatches [GameEvents] through [EventHandler]s.
/// Every [EventHandler] intercepts event and can proceed it
/// or convert to any other events.
class ProcessingEventChannel extends AbstractEventChannel {
  final List<EventHandler> processors;

  ProcessingEventChannel(this.processors)
      : assert(processors != null),
        assert(processors.isNotEmpty);

  @override
  Stream<GameEvent> sendEvent(GameEvent event) =>
      _dispatchEventToProcessor(event, 0);

  Stream<GameEvent> _dispatchEventToProcessor(GameEvent input, int level) =>
      level == processors.length
          ? Stream.value(input)
          : processors[level].process(input).asyncExpand(
              (event) => _dispatchEventToProcessor(event, level + 1));
}
