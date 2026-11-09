// Texts that lib/base and lib/remote used to hard-code now come from the
// generated strings. These tests pin them to the texts the player saw.

import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';

void main() {
  final t = AppLocale.ru.buildSync();

  test('default player names', () {
    expect(t.players.player, 'Игрок');
    expect(t.players.android, 'Андроид');
    expect(t.players.firstPlayer, 'Игрок 1');
    expect(t.players.secondPlayer, 'Игрок 2');
  });

  test('unknown country', () {
    expect(t.citiesList.unkCity, 'Неизвестно');
  });

  test('hint that is not ready', () {
    expect(t.game.hintUnavailable, 'На эту букву подсказок больше нет');
  });
}
