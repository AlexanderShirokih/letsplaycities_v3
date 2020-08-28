import 'package:lets_play_cities/base/game/management.dart';
import 'package:lets_play_cities/base/game/handlers.dart';

/// Intercepts [RawWordEvent] for trusted users and immediately converts this
/// word to [Accepted] event.
class TrustedEventsInterceptor extends TypedEventHandler<RawWordEvent> {
  @override
  Stream<GameEvent> processTypedEvent(RawWordEvent event) {
    return Stream.value(
      event.owner.isTrusted ? Accepted(event.word, event.owner) : event,
    );
  }
}
