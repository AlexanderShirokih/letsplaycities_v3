import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/game/combo.dart';
import 'package:lets_play_cities/base/game/player/surrender_exception.dart';

import 'fakes.dart';

void main() {
  group('Player', () {
    test('answers with the typed city in its normal form', () async {
      final player = createPlayer();

      final word = player.onCreateWord('м');
      player.onUserInput('  Мёртвое--Море ');

      expect(await word, 'мертвое-море');
    });

    test('surrenders by disconnection when closed during its move', () async {
      final player = createPlayer();

      final word = expectLater(
        player.onCreateWord('м'),
        throwsA(
          isA<SurrenderException>()
              .having((e) => e.target, 'target', same(player))
              .having((e) => e.byDisconnection, 'byDisconnection', isTrue),
        ),
      );
      await player.close();

      await word;
    });

    test('its words are checked and can earn the quick answer combo', () {
      final player = createPlayer();

      for (var i = 0; i < 3; i++) {
        player.comboSystem.addCity(
          CityComboInfo.fromMoveParams(0, 'москва', 0),
        );
      }

      expect(player.isTrusted, isFalse);
      expect(player.comboSystem.activeCombos.keys, [ComboType.quickTime]);
    });
  });

  group('User score', () {
    test('starts at zero and shows only the name until it grows', () {
      final player = createPlayer('Вася');

      expect(player.score, 0);
      expect(player.info, 'Вася');

      player.increaseScore(6);

      expect(player.score, 6);
      expect(player.info, 'Вася: 6');
    });

    test('multiplies the points by the active combos and rounds down', () {
      final player = createPlayer();
      // Three short cities in a row: SHORT_WORD combo, multiplier 1.5.
      for (var i = 0; i < 3; i++) {
        player.comboSystem.addCity(
          CityComboInfo.fromMoveParams(10000, 'ухта', 0),
        );
      }

      player.increaseScore(5);
      expect(player.score, 7);

      player.increaseScore(5);
      expect(player.score, 14);
    });
  });
}
