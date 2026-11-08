import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/game/handlers.dart';
import 'package:lets_play_cities/base/game/management.dart';

import 'fake_users.dart';

void main() {
  test('accepts a trusted user\'s word without further checks', () async {
    final android = FakeOpponent(isTrusted: true);

    final result = await TrustedEventsInterceptor()
        .process(RawWordEvent('москва', android))
        .toList();

    expect(result, [
      isA<Accepted>()
          .having((e) => e.word, 'word', 'москва')
          .having((e) => e.owner, 'owner', same(android))
          .having((e) => e.status, 'status', CityStatus.ok)
          .having((e) => e.isSuccessful(), 'isSuccessful', isTrue),
    ]);
  });

  test('passes an untrusted user\'s word on to the checks', () async {
    final word = RawWordEvent('москва', newPlayer());

    final result = await TrustedEventsInterceptor().process(word).toList();

    expect(result, [same(word)]);
  });

  test('passes events other than words through', () async {
    const event = OnFirstCharChanged('а');

    final result = await TrustedEventsInterceptor().process(event).toList();

    expect(result, [same(event)]);
  });
}
