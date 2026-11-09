import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/dictionary.dart';
import 'package:lets_play_cities/base/dictionary/countrycode_overrides.dart';
import 'package:lets_play_cities/base/dictionary/impl/dictionary_impl.dart';
import 'package:lets_play_cities/base/game/game_mode.dart';
import 'package:lets_play_cities/base/game/handlers.dart';
import 'package:lets_play_cities/base/game/management.dart';
import 'package:lets_play_cities/base/game/rules/classic_rules.dart';
import 'package:lets_play_cities/base/scoring.dart';

import '../handlers/fake_users.dart';

class _Word extends GameEvent {
  final String word;

  const _Word(this.word);

  @override
  String toString() => word;
}

/// Logs every event it sees as `name:event` and replaces it with
/// whatever [convert] returns.
class _LoggingHandler extends EventHandler {
  final String name;
  final List<String> log;
  final List<GameEvent> Function(GameEvent event) convert;

  _LoggingHandler(
    this.name,
    this.log, {
    List<GameEvent> Function(GameEvent)? convert,
  }) : convert = convert ?? ((event) => [event]);

  @override
  Stream<GameEvent> process(GameEvent event) {
    log.add('$name:$event');
    return Stream.fromIterable(convert(event));
  }
}

class _FakeExclusions extends Fake implements ExclusionsService {
  final Map<String, String> descriptions;

  _FakeExclusions(this.descriptions);

  @override
  String checkForExclusion(String city) => descriptions[city] ?? '';
}

class _NoOverrides implements CountryCodeOverrides {
  @override
  int? findOverride(String word) => null;
}

void main() {
  group('ProcessingEventChannel', () {
    test('passes an event through every processor in order', () async {
      final log = <String>[];
      final channel = ProcessingEventChannel([
        _LoggingHandler('a', log),
        _LoggingHandler('b', log),
        _LoggingHandler('c', log),
      ]);

      final result = await channel.sendEvent(const _Word('x')).toList();

      expect(result.map((e) => '$e'), ['x']);
      expect(log, ['a:x', 'b:x', 'c:x']);
    });

    test('sends every emitted event through the rest of the chain', () async {
      final log = <String>[];
      final channel = ProcessingEventChannel([
        _LoggingHandler(
          'split',
          log,
          convert: (e) => [_Word('${e}1'), _Word('${e}2')],
        ),
        _LoggingHandler('b', log),
        _LoggingHandler('c', log),
      ]);

      final result = await channel.sendEvent(const _Word('x')).toList();

      expect(result.map((e) => '$e'), ['x1', 'x2']);
      // The first event finishes the whole chain before the second starts.
      expect(log, ['split:x', 'b:x1', 'c:x1', 'b:x2', 'c:x2']);
    });

    test('a processor that emits nothing stops the event', () async {
      final log = <String>[];
      final channel = ProcessingEventChannel([
        _LoggingHandler('drop', log, convert: (_) => []),
        _LoggingHandler('b', log),
      ]);

      final result = await channel.sendEvent(const _Word('x')).toList();

      expect(result, isEmpty);
      expect(log, ['drop:x']);
    });

    test('a converted event is not seen by earlier processors', () async {
      final log = <String>[];
      final channel = ProcessingEventChannel([
        _LoggingHandler('a', log),
        _LoggingHandler('convert', log, convert: (_) => [const _Word('y')]),
        _LoggingHandler('c', log),
      ]);

      final result = await channel.sendEvent(const _Word('x')).toList();

      expect(result.map((e) => '$e'), ['y']);
      expect(log, ['a:x', 'convert:x', 'c:y']);
    });

    test('requires at least one processor', () {
      expect(() => ProcessingEventChannel([]), throwsAssertionError);
    });
  });

  group('the game handler stack', () {
    late DictionaryService dictionary;
    late ProcessingEventChannel channel;

    setUp(() {
      dictionary = DictionaryServiceImpl({
        'москва': CityProperties(difficulty: 0, countryCode: 7),
        'абакан': CityProperties(difficulty: 0, countryCode: 7),
        'ссср': CityProperties(difficulty: 0, countryCode: 7),
      });
      // The same order as GameSessionFactory builds it.
      channel = ProcessingEventChannel([
        TrustedEventsInterceptor(),
        FirstLetterChecker(),
        ExclusionsChecker(_FakeExclusions({'ссср': 'это страна'})),
        DatabaseChecker(dictionary),
        Endpoint(
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
            ScoringType.byScore,
          ),
        ),
      ]);
    });

    Future<List<GameEvent>> send(GameEvent event) =>
        channel.sendEvent(event).toList();

    Matcher committed(String word) => isA<Accepted>()
        .having((e) => e.word, 'word', word)
        .having((e) => e.status, 'status', CityStatus.ok)
        .having((e) => e.countryCode, 'countryCode', 7);

    test('commits a valid word, so it cannot be used again', () async {
      final player = newPlayer();

      expect(await send(RawWordEvent('москва', player)), [committed('москва')]);
      expect(await send(RawWordEvent('москва', player)), [
        isA<AlreadyUsed>().having((e) => e.word, 'word', 'москва'),
      ]);
    });

    test('rejects a wrong first letter without using up the word', () async {
      final player = newPlayer();
      final firstChar = await send(const OnFirstCharChanged('а'));
      expect(firstChar, [isA<OnFirstCharChanged>()]);

      expect(await send(RawWordEvent('москва', player)), [
        isA<WrongLetter>().having((e) => e.validLetter, 'validLetter', 'а'),
      ]);
      expect(await dictionary.checkCity('москва'), CityResult.ok);
    });

    test('commits a trusted user\'s word without checking it', () async {
      await send(const OnFirstCharChanged('а'));

      expect(await send(RawWordEvent('москва', FakeOpponent())), [
        committed('москва'),
      ]);
      expect(await dictionary.checkCity('москва'), CityResult.alreadyUsed);
    });

    test('rejects an exclusion even if the dictionary has it', () async {
      expect(await send(RawWordEvent('ссср', newPlayer())), [
        isA<Exclusion>().having(
          (e) => e.description,
          'description',
          'это страна',
        ),
      ]);
      expect(await dictionary.checkCity('ссср'), CityResult.ok);
    });

    test('commits the only correction of a typo', () async {
      expect(await send(RawWordEvent('масква', newPlayer())), [
        isA<Corrections>().having((e) => e.corrections, 'corrections', {
          'москва',
        }),
        committed('москва'),
      ]);
      expect(await dictionary.checkCity('москва'), CityResult.alreadyUsed);
    });
  });
}
