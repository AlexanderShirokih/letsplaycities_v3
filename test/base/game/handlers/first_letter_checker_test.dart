import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/game/handlers.dart';
import 'package:lets_play_cities/base/game/management.dart';
import 'package:lets_play_cities/base/users.dart';

import 'fake_users.dart';

void main() {
  final player = Player(
    LocalAccountInfo(name: 'player', picture: const PlaceholderPictureSource()),
  );

  test('accepts any letter before the first char is known', () async {
    final checker = FirstLetterChecker();
    final word = RawWordEvent('москва', player);

    expect(await checker.process(word).toList(), [word]);
  });

  test('rejects a word with a wrong first letter', () async {
    final checker = FirstLetterChecker();
    await checker.process(const OnFirstCharChanged('а')).toList();

    final result = await checker
        .process(RawWordEvent('москва', player))
        .toList();

    expect(result.single, isA<WrongLetter>());
    expect((result.single as WrongLetter).validLetter, 'а');
  });

  test('accepts a word that starts with the expected letter', () async {
    final checker = FirstLetterChecker();
    await checker.process(const OnFirstCharChanged('а')).toList();
    final word = RawWordEvent('абакан', player);

    expect(await checker.process(word).toList(), [same(word)]);
  });

  test('passes the first char change on to the next handlers', () async {
    // Endpoint times the move from this event, so it must not be swallowed.
    const event = OnFirstCharChanged('а');

    expect(await FirstLetterChecker().process(event).toList(), [same(event)]);
  });

  test('checks against the latest first char', () async {
    final checker = FirstLetterChecker();
    await checker.process(const OnFirstCharChanged('а')).toList();
    await checker.process(const OnFirstCharChanged('м')).toList();
    final moscow = RawWordEvent('москва', player);

    expect(await checker.process(moscow).toList(), [same(moscow)]);
    expect(await checker.process(RawWordEvent('абакан', player)).toList(), [
      isA<WrongLetter>().having((e) => e.validLetter, 'validLetter', 'м'),
    ]);
  });

  test('an empty first char accepts any letter again', () async {
    final checker = FirstLetterChecker();
    await checker.process(const OnFirstCharChanged('а')).toList();
    await checker.process(const OnFirstCharChanged('')).toList();
    final word = RawWordEvent('москва', player);

    expect(await checker.process(word).toList(), [same(word)]);
  });

  test('does not check the words of trusted users', () async {
    final checker = FirstLetterChecker();
    await checker.process(const OnFirstCharChanged('а')).toList();
    final word = RawWordEvent('москва', FakeOpponent(isTrusted: true));

    expect(await checker.process(word).toList(), [same(word)]);
  });

  test('checks the words of untrusted opponents', () async {
    final checker = FirstLetterChecker();
    await checker.process(const OnFirstCharChanged('а')).toList();

    final result = await checker
        .process(RawWordEvent('москва', FakeOpponent(isTrusted: false)))
        .toList();

    expect(result, [isA<WrongLetter>()]);
  });
}
