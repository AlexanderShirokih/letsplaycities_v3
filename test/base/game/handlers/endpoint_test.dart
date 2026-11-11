import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/dictionary.dart';
import 'package:lets_play_cities/base/dictionary/countrycode_overrides.dart';
import 'package:lets_play_cities/base/game/combo.dart';
import 'package:lets_play_cities/base/game/game_mode.dart';
import 'package:lets_play_cities/base/game/handlers.dart';
import 'package:lets_play_cities/base/game/management.dart';
import 'package:lets_play_cities/base/game/rules/classic_rules.dart';
import 'package:lets_play_cities/base/scoring.dart';
import 'package:lets_play_cities/base/users.dart';

import 'fake_users.dart';

class _FakeDictionary extends Fake implements DictionaryService {
  final used = <String>[];

  @override
  void markUsed(String city) => used.add(city);

  @override
  int getCountryCode(String city) => 7;
}

class _NoOverrides implements CountryCodeOverrides {
  @override
  int? findOverride(String word) => null;
}

class _Overrides implements CountryCodeOverrides {
  final Map<String, int> codes;

  _Overrides(this.codes);

  @override
  int? findOverride(String word) => codes[word];
}

class _Move {
  final User user;
  final String word;
  final int moveTimeInMs;
  final Map<int, int> activeCombos;

  _Move(this.user, this.word, this.moveTimeInMs, this.activeCombos);
}

class _SpyScoreController extends Fake implements ScoreController {
  final moves = <_Move>[];

  @override
  void onMoveFinished(
    User user,
    String word,
    int moveTimeInMs,
    Map<int, int> activeCombos,
  ) => moves.add(_Move(user, word, moveTimeInMs, activeCombos));
}

void main() {
  test('handles a word accepted before the first char is known', () async {
    final dictionary = _FakeDictionary();
    final player = Player(
      LocalAccountInfo(
        name: 'player',
        picture: const PlaceholderPictureSource(),
      ),
    );
    final endpoint = Endpoint(
      dictionary,
      _NoOverrides(),
      () {},
      () {},
      ClassicRules(
        ScoreController(
          ScoringSet.initial(),
          ScoringType.byScore,
          GameMode.playerVsAndroid,
          (_) {},
        ),
      ),
    );

    final result = await endpoint.process(Accepted('москва', player)).toList();

    final accepted = result.single as Accepted;
    expect(accepted.status, CityStatus.ok);
    expect(accepted.countryCode, 7);
    expect(dictionary.used, ['москва']);
    expect(player.score, 'москва'.length);
  });

  group('accepted words', () {
    late _FakeDictionary dictionary;
    late _SpyScoreController scores;
    late int inputAcceptedCalls;

    setUp(() {
      dictionary = _FakeDictionary();
      scores = _SpyScoreController();
      inputAcceptedCalls = 0;
    });

    Endpoint endpoint({CountryCodeOverrides? overrides}) => Endpoint(
      dictionary,
      overrides ?? _NoOverrides(),
      () => inputAcceptedCalls++,
      () {},
      ClassicRules(scores),
    );

    test('take the overridden country code over the dictionary one', () async {
      final result = await endpoint(overrides: _Overrides({'киев': 380}))
          .process(Accepted('киев', newPlayer()))
          .toList();

      expect(result, [
        isA<Accepted>().having((e) => e.countryCode, 'countryCode', 380),
      ]);
    });

    test('take the dictionary country code when not overridden', () async {
      final result = await endpoint(overrides: _Overrides({'киев': 380}))
          .process(Accepted('москва', newPlayer()))
          .toList();

      expect(result, [
        isA<Accepted>().having((e) => e.countryCode, 'countryCode', 7),
      ]);
    });

    test('clear the input field only for the local player', () async {
      final handler = endpoint();

      await handler.process(Accepted('москва', newPlayer())).toList();
      expect(inputAcceptedCalls, 1);

      await handler.process(Accepted('абакан', FakeOpponent())).toList();
      expect(inputAcceptedCalls, 1);
    });

    test(
      'clear the input and score when the listener stops at the word',
      () async {
        // The move loop of the game session returns at the first accepted word
        await endpoint().process(Accepted('москва', newPlayer())).first;

        expect(inputAcceptedCalls, 1);
        expect(scores.moves, hasLength(1));
      },
    );

    test('of an opponent are committed and scored too', () async {
      final opponent = FakeOpponent();

      final result = await endpoint()
          .process(Accepted('москва', opponent, status: CityStatus.ok))
          .toList();

      expect(result, [
        isA<Accepted>()
            .having((e) => e.owner, 'owner', same(opponent))
            .having((e) => e.status, 'status', CityStatus.ok),
      ]);
      expect(dictionary.used, ['москва']);
      expect(scores.moves.single.user, same(opponent));
    });
  });

  group('other events', () {
    test('pass through without committing or scoring anything', () async {
      final dictionary = _FakeDictionary();
      final scores = _SpyScoreController();
      var inputAcceptedCalls = 0;
      final handler = Endpoint(
        dictionary,
        _NoOverrides(),
        () => inputAcceptedCalls++,
        () {},
        ClassicRules(scores),
      );
      final events = <GameEvent>[
        const NotFound('масква'),
        const AlreadyUsed('москва'),
        const WrongLetter('а'),
        Corrections({'москва'}),
        MessageEvent('привет', newPlayer()),
      ];

      for (final event in events) {
        expect(await handler.process(event).toList(), [same(event)]);
      }
      expect(dictionary.used, isEmpty);
      expect(scores.moves, isEmpty);
      expect(inputAcceptedCalls, 0);
    });

    test('a turn passed to the local player begins its move', () async {
      var moveBeginsCalls = 0;
      final handler = Endpoint(
        _FakeDictionary(),
        _NoOverrides(),
        () {},
        () => moveBeginsCalls++,
        ClassicRules(_SpyScoreController()),
      );
      final player = newPlayer();
      final opponent = FakeOpponent();
      final toOpponent = OnUserSwitchedEvent(opponent, [player, opponent]);
      final toPlayer = OnUserSwitchedEvent(player, [player, opponent]);

      expect(await handler.process(toOpponent).toList(), [same(toOpponent)]);
      expect(moveBeginsCalls, 0);

      expect(await handler.process(toPlayer).toList(), [same(toPlayer)]);
      expect(moveBeginsCalls, 1);
    });

    test('a timed out local player gets the input cleared', () async {
      var inputAcceptedCalls = 0;
      final handler = Endpoint(
        _FakeDictionary(),
        _NoOverrides(),
        () => inputAcceptedCalls++,
        () {},
        ClassicRules(_SpyScoreController()),
      );
      final ofOpponent = MoveSkipped(FakeOpponent());
      final ofPlayer = MoveSkipped(newPlayer());

      expect(await handler.process(ofOpponent).toList(), [same(ofOpponent)]);
      expect(inputAcceptedCalls, 0);

      expect(await handler.process(ofPlayer).toList(), [same(ofPlayer)]);
      expect(inputAcceptedCalls, 1);
    });
  });

  group('move time', () {
    /// Runs [handler] on [event] and lets it finish in fake time.
    List<GameEvent> process(
      FakeAsync async,
      Endpoint handler,
      GameEvent event,
    ) {
      final result = <GameEvent>[];
      handler.process(event).listen(result.add);
      async.flushMicrotasks();
      return result;
    }

    Endpoint endpoint(ScoreController scores) => Endpoint(
      _FakeDictionary(),
      _NoOverrides(),
      () {},
      () {},
      ClassicRules(scores),
    );

    test('is counted from the last first char change', () {
      fakeAsync((async) {
        final scores = _SpyScoreController();
        final handler = endpoint(scores);
        final player = newPlayer();

        async.elapse(const Duration(seconds: 10));
        process(async, handler, const OnFirstCharChanged('а'));
        async.elapse(const Duration(milliseconds: 4200));
        process(async, handler, Accepted('абакан', player));

        process(async, handler, const OnFirstCharChanged('н'));
        async.elapse(const Duration(milliseconds: 700));
        process(async, handler, Accepted('нальчик', player));

        expect(scores.moves.map((m) => m.moveTimeInMs), [4200, 700]);
      });
    });

    test('is counted from creation before the first char is known', () {
      fakeAsync((async) {
        final scores = _SpyScoreController();
        final handler = endpoint(scores);

        async.elapse(const Duration(milliseconds: 1500));
        process(async, handler, Accepted('москва', newPlayer()));

        expect(scores.moves.single.moveTimeInMs, 1500);
      });
    });

    test('three quick moves start the quick-time combo on the third', () {
      fakeAsync((async) {
        final scores = _SpyScoreController();
        final handler = endpoint(scores);
        final player = newPlayer();

        for (final word in ['москва', 'абакан', 'нальчик']) {
          process(async, handler, const OnFirstCharChanged(''));
          async.elapse(const Duration(seconds: 3));
          process(async, handler, Accepted(word, player));
        }

        expect(scores.moves.map((m) => m.activeCombos), [
          isEmpty,
          isEmpty,
          {ComboType.quickTime.index: 1},
        ]);
      });
    });

    test('slow moves do not start the quick-time combo', () {
      fakeAsync((async) {
        final scores = _SpyScoreController();
        final handler = endpoint(scores);
        final player = newPlayer();

        for (final word in ['москва', 'абакан', 'нальчик']) {
          process(async, handler, const OnFirstCharChanged(''));
          async.elapse(const Duration(seconds: 6));
          process(async, handler, Accepted(word, player));
        }

        expect(scores.moves.last.activeCombos, isEmpty);
      });
    });
  });
}
