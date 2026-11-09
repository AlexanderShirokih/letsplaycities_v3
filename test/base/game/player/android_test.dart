import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/dictionary.dart';
import 'package:lets_play_cities/base/game/combo.dart';
import 'package:lets_play_cities/base/game/player/skip_move_exception.dart';
import 'package:lets_play_cities/base/game/player/surrender_exception.dart';
import 'package:lets_play_cities/base/users.dart';

import 'fakes.dart';

/// Asks [android] for words until it surrenders and returns how many words
/// it gave before that.
Future<int> _countWordsBeforeSurrender(Android android) async {
  var words = 0;
  while (true) {
    try {
      await android.onCreateWord('а');
      words++;
    } on SurrenderException {
      return words;
    }
  }
}

void main() {
  test('answers with a dictionary word after a 1.5 second pause', () {
    fakeAsync((async) {
      final dictionary = FakeDictionary(words: ['анапа']);
      final android = Android(dictionary, 'android', random: FixedRandom(0));

      String? word;
      android.onCreateWord('а').then((w) => word = w);

      async.elapse(const Duration(milliseconds: 1499));
      expect(word, isNull);
      expect(dictionary.requests, isEmpty);

      async.elapse(const Duration(milliseconds: 1));
      expect(word, 'анапа');
      expect(dictionary.requests, ['а']);
    });
  });

  test('surrenders when the dictionary has no word left', () {
    fakeAsync((async) {
      final android = Android(
        FakeDictionary(words: const []),
        'android',
        random: FixedRandom(0),
      );

      Object? error;
      android.onCreateWord('ы').catchError((Object e) {
        error = e;
        return '';
      });
      async.elapse(const Duration(milliseconds: 1500));

      expect(
        error,
        isA<SurrenderException>()
            .having((e) => e.target, 'target', same(android))
            .having((e) => e.byDisconnection, 'byDisconnection', isFalse),
      );
    });
  });

  group('gives up after a number of moves that grows with difficulty', () {
    Future<int> movesFor(Difficulty difficulty, double random) =>
        _countWordsBeforeSurrender(
          Android(
            EndlessDictionary(difficulty),
            'android',
            moveDelay: Duration.zero,
            random: FixedRandom(random),
          ),
        );

    test('at the lowest random roll', () async {
      expect(await movesFor(Difficulty.easy, 0), 20);
      expect(await movesFor(Difficulty.medium, 0), 43);
      expect(await movesFor(Difficulty.hard, 0), 66);
    });

    test('up to 35% more at the highest random roll', () async {
      expect(await movesFor(Difficulty.easy, 0.9999), 26);
      expect(await movesFor(Difficulty.hard, 0.9999), 89);
    });
  });

  test('its words are trusted but never earn the quick answer combo', () {
    final android = Android(
      FakeDictionary(),
      'android',
      random: FixedRandom(0),
    );

    for (var i = 0; i < 3; i++) {
      android.comboSystem.addCity(CityComboInfo.fromMoveParams(0, 'москва', 0));
    }

    expect(android.isTrusted, isTrue);
    expect(android.comboSystem.activeCombos, isEmpty);
  });

  group('in a route game', () {
    test('never gives up while it has a city', () async {
      final android = Android(
        EndlessDictionary(Difficulty.easy),
        'android',
        moveDelay: Duration.zero,
        random: FixedRandom(0),
        routeWord: (firstChar) async => '$firstChar-route',
      );

      for (var move = 0; move < 100; move++) {
        expect(await android.onCreateWord('а'), 'а-route');
      }
    });

    test('skips the move at once when it has no city', () {
      fakeAsync((async) {
        final android = Android(
          FakeDictionary(),
          'android',
          random: FixedRandom(0),
          routeWord: (_) async => null,
        );

        Object? error;
        android.onCreateWord('ы').catchError((Object e) {
          error = e;
          return '';
        });
        async.flushMicrotasks();

        expect(
          error,
          isA<SkipMoveException>().having(
            (e) => e.target,
            'target',
            same(android),
          ),
        );
      });
    });

    test('answers with its city after the pause', () {
      fakeAsync((async) {
        final android = Android(
          FakeDictionary(),
          'android',
          random: FixedRandom(0),
          routeWord: (_) async => 'анапа',
        );

        String? word;
        android.onCreateWord('а').then((w) => word = w);

        async.elapse(const Duration(milliseconds: 1499));
        expect(word, isNull);

        async.elapse(const Duration(milliseconds: 1));
        expect(word, 'анапа');
      });
    });
  });
}
