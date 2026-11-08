import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/game/management.dart';

import '../handlers/fake_users.dart';

void main() {
  group('a server verdict on a word', () {
    final player = newPlayer();

    WordCheckingResult of(WordResult result) =>
        WordCheckingResult.of(result, player, 'москва');

    test('ACCEPTED accepts the word for its owner', () {
      expect(
        of(WordResult.accepted),
        isA<Accepted>()
            .having((e) => e.word, 'word', 'москва')
            .having((e) => e.owner, 'owner', same(player)),
      );
    });

    test('ALREADY and NO_WORD reject the word', () {
      expect(
        of(WordResult.already),
        isA<AlreadyUsed>().having((e) => e.word, 'word', 'москва'),
      );
      expect(
        of(WordResult.noWord),
        isA<NotFound>().having((e) => e.word, 'word', 'москва'),
      );
    });

    test('WRONG_MOVE is reported as a wrong move error', () {
      expect(
        of(WordResult.wrongMove),
        isA<Error>().having(
          (e) => e.exception,
          'exception',
          isA<WrongMoveException>(),
        ),
      );
    });

    test('WRONG_LETTER asks for the valid letter', () {
      expect(
        WordCheckingResult.of(
          WordResult.wrongLetter,
          player,
          'москва',
          validLetter: 'а',
        ),
        isA<WrongLetter>().having((e) => e.validLetter, 'validLetter', 'а'),
      );
    });

    test('RECEIVED and UNKNOWN are reported as errors', () {
      for (final result in [WordResult.received, WordResult.unknown]) {
        expect(
          of(result),
          isA<Error>().having(
            (e) => e.exception,
            'exception',
            allOf(
              isA<WordCheckingException>(),
              isNot(isA<WrongMoveException>()),
            ),
          ),
          reason: '$result',
        );
      }
    });
  });

  test('only rejections are shown to the user as an error message', () {
    final player = newPlayer();
    final rejections = <WordCheckingResult>[
      const AlreadyUsed('москва'),
      const WrongLetter('а'),
      const Exclusion('это страна'),
      const NotFound('масква'),
      const Error(WrongMoveException()),
    ];
    final notErrors = <WordCheckingResult>[
      Corrections({'москва'}),
      Accepted('москва', player),
    ];

    expect(rejections.where((r) => !r.isDescriptiveError()), isEmpty);
    expect(notErrors.where((r) => r.isDescriptiveError()), isEmpty);
  });

  group('Accepted', () {
    test('is successful only once committed with status OK', () {
      final accepted = Accepted('москва', newPlayer());

      expect(accepted.isSuccessful(), isFalse);
      expect(
        accepted.clone(status: CityStatus.waiting).isSuccessful(),
        isFalse,
      );
      expect(accepted.clone(status: CityStatus.ok).isSuccessful(), isTrue);
    });

    test('clone keeps the word and owner and fields not given', () {
      final player = newPlayer();
      final original = Accepted(
        'москва',
        player,
        status: CityStatus.waiting,
        countryCode: 7,
      );

      final withCode = original.clone(countryCode: 380);
      final withStatus = original.clone(status: CityStatus.ok);

      expect(withCode.word, 'москва');
      expect(withCode.owner, same(player));
      expect(withCode.status, CityStatus.waiting);
      expect(withCode.countryCode, 380);
      expect(withStatus.countryCode, 7);
      expect(withStatus.status, CityStatus.ok);
    });
  });
}
