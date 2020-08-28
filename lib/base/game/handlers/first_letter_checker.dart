import 'package:lets_play_cities/base/game/management.dart';
import 'package:lets_play_cities/base/game/handlers.dart';

/// Checks that the first letter matches
/// Emits [WrongLetter] if first letter of the [RawWordEvent] doesn't matches
/// with last char of the last accepted word.
/// Last chars should be updated by passing [OnFirstCharChanged] to event queue.
class FirstLetterChecker extends EventHandler {
  String _firstChar;

  @override
  Stream<GameEvent> process(GameEvent event) async* {
    if (event is OnFirstCharChanged) _firstChar = event.firstChar;

    if (!(event is RawWordEvent) ||
        (event as RawWordEvent).owner.isTrusted ||
        _checkFirstLetterMatches((event as RawWordEvent).word)) {
      yield event;
      return;
    }

    yield WrongLetter(_firstChar);
  }

  bool _checkFirstLetterMatches(String userInput) =>
      _firstChar.isEmpty || userInput.startsWith(_firstChar);
}
