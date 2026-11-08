import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/game/turn_gate.dart';
import 'package:lets_play_cities/base/users.dart';

Player _player(String name) => Player(
  LocalAccountInfo(name: name, picture: const PlaceholderPictureSource()),
);

void main() {
  final first = _player('first');
  final second = _player('second');

  test('turn gate waits until release', () async {
    final gate = TurnGate();
    var passed = false;

    final wait = gate.waitFor(first).then((_) => passed = true);
    await pumpEventQueue();

    expect(passed, isFalse);
    expect(gate.waiting.value, same(first));

    gate.release();
    await wait;

    expect(passed, isTrue);
    expect(gate.waiting.value, isNull);
  });

  test('double release starts one move', () async {
    final gate = TurnGate();

    final firstWait = gate.waitFor(first);
    gate
      ..release()
      ..release();
    await firstWait;

    var secondPassed = false;
    gate.waitFor(second).then((_) => secondPassed = true);
    await pumpEventQueue();

    expect(secondPassed, isFalse);
    expect(gate.waiting.value, same(second));
  });

  test('release without a wait is a no-op', () async {
    final gate = TurnGate()..release();

    var passed = false;
    gate.waitFor(first).then((_) => passed = true);
    await pumpEventQueue();

    expect(passed, isFalse);
  });

  test('cancel completes pending wait', () async {
    final gate = TurnGate();
    var passed = false;

    final wait = gate.waitFor(first).then((_) => passed = true);
    gate.cancel();
    await wait;

    expect(passed, isTrue);
    expect(gate.waiting.value, isNull);

    // A cancelled gate no longer stops the game.
    await gate.waitFor(second);
    expect(gate.waiting.value, isNull);
  });
}
