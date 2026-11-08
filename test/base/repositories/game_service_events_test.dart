import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/game/management.dart';
import 'package:lets_play_cities/base/repositories/game_service_events.dart';

void main() {
  test('getTimerTicks() emits the seconds left of every timer tick', () {
    final repository = GameServiceEventsRepository(
      Stream.fromIterable(const [
        TimeEvent(75),
        OnFirstCharChanged('а'),
        TimeEvent(74),
      ]),
    );

    expect(repository.getTimerTicks(), emitsInOrder([75, 74, emitsDone]));
  });

  test('getFirstChars emits letters', () {
    final repository = GameServiceEventsRepository(
      Stream.fromIterable(const [TimeEvent(75), OnFirstCharChanged('м')]),
    );

    expect(repository.getFirstChars(), emitsInOrder(['м', emitsDone]));
  });
}
