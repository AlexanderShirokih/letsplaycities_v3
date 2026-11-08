import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/game/combo.dart';
import 'package:lets_play_cities/base/game/game_summary.dart';
import 'package:lets_play_cities/base/users.dart';

import 'player/fakes.dart';

Android _android() => Android(FakeDictionary(), 'android');

void main() {
  test('summary counts cities and duration', () {
    var now = DateTime(2026, 11, 8, 12);
    final builder = GameSummaryBuilder(Clock(() => now))..start();
    final player = createPlayer();
    final android = _android();

    builder.onAccepted(player, 'москва', 1);
    now = now.add(const Duration(seconds: 40));
    builder.onAccepted(android, 'анапа', 1);
    now = now.add(const Duration(seconds: 50));
    builder.onAccepted(player, 'амстердам', 2);

    final summary = builder.build();

    expect(summary.citiesCount, 3);
    expect(summary.duration, const Duration(seconds: 90));
  });

  test('duration is zero when no move has started', () {
    final builder = GameSummaryBuilder(Clock.fixed(DateTime(2026)));

    expect(builder.build(), GameSummary.empty);
  });

  test('longest city only from players', () {
    final builder = GameSummaryBuilder(Clock.fixed(DateTime(2026)))..start();
    final player = createPlayer();

    builder
      ..onAccepted(_android(), 'петропавловск-камчатский', 1)
      ..onAccepted(player, 'новосибирск', 1)
      ..onAccepted(player, 'омск', 1);

    expect(builder.build().longestCity, (city: 'новосибирск', countryCode: 1));
  });

  test('player countries skip other users and unknown codes', () {
    final builder = GameSummaryBuilder(Clock.fixed(DateTime(2026)))..start();
    final first = createPlayer('first');
    final second = createPlayer('second');

    builder
      ..onAccepted(first, 'москва', 1)
      ..onAccepted(_android(), 'анкара', 40)
      ..onAccepted(second, 'амстердам', 25)
      ..onAccepted(first, 'минск', 0)
      ..onAccepted(second, 'казань', 1);

    expect(builder.build().playerCountries, {1, 25});
  });

  test('best combos keep max', () {
    final builder = GameSummaryBuilder(Clock.fixed(DateTime(2026)))..start();
    final player = createPlayer();

    builder
      ..onCombos(player, {ComboType.quickTime: 2})
      ..onCombos(player, {ComboType.quickTime: 4, ComboType.shortWord: 1})
      ..onCombos(player, {ComboType.quickTime: 3})
      ..onCombos(_android(), {ComboType.quickTime: 7, ComboType.longWord: 2});

    expect(builder.build().bestCombos, {
      ComboType.quickTime: 4,
      ComboType.shortWord: 1,
    });
  });
}
