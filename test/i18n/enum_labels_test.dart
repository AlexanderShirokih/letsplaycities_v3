// The screens used to pick these texts from lists by enum index. Each test
// lists the texts in the order of the old list, so the labels match what
// the index gave.

import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/achievements/achievements.dart';
import 'package:lets_play_cities/base/dictionary/dictionary.dart';
import 'package:lets_play_cities/base/dictionary/dictionary_update_period.dart';
import 'package:lets_play_cities/base/game/combo/combo_type.dart';
import 'package:lets_play_cities/base/game/game_result.dart';
import 'package:lets_play_cities/base/game/management/game_events.dart';
import 'package:lets_play_cities/base/scoring/scoring_type.dart';
import 'package:lets_play_cities/i18n/enum_labels.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';

void main() {
  final t = AppLocale.ru.buildSync();

  test('achievements have distinct titles', () {
    final titles = Achievement.values.map((v) => v.label(t)).toList();

    expect(titles, everyElement(isNotEmpty));
    expect(titles.toSet(), hasLength(Achievement.values.length));
    expect(Achievement.write15Cities.label(t), '15 городов');
  });

  test('combo types', () {
    expect(ComboType.values.map((v) => v.label(t)), [
      'Быстрый ответ',
      'Короткие города',
      'Длинные города',
      'Одна страна',
      'Разные страны',
    ]);
  });

  test('match results', () {
    expect(MatchResult.values.map((v) => v.label(t)), [
      'Победа!',
      'Поражение',
      'Ничья',
    ]);
  });

  test('difficulties', () {
    expect(Difficulty.values.map((v) => v.label(t)), [
      'Легко',
      'Нормально',
      'Сложно',
    ]);
  });

  test('scoring types', () {
    expect(ScoringType.values.map((v) => v.label(t)), [
      'По очкам',
      'По времени',
      'До сдачи',
    ]);
  });

  test('dictionary update periods', () {
    expect(DictionaryUpdatePeriod.values.map((v) => v.label(t)), [
      'Выкл',
      'Каждые 3ч',
      'Каждый день',
    ]);
  });

  group('move finish descriptions', () {
    test('name who ended the game', () {
      expect(
        MoveFinishType.timeout.finishDescription(t, 'Вася'),
        'У Вася вышло время',
      );
      expect(
        MoveFinishType.disconnected.finishDescription(t, 'Вася'),
        'Вася отключился',
      );
      expect(
        MoveFinishType.surrender.finishDescription(t, 'Вася'),
        'Вася сдался',
      );
    });

    test('do not exist for a completed move', () {
      expect(
        () => MoveFinishType.completed.finishDescription(t, 'Вася'),
        throwsStateError,
      );
    });
  });
}
