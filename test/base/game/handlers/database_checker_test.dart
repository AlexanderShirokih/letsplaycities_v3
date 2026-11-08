import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/dictionary.dart';
import 'package:lets_play_cities/base/game/handlers.dart';
import 'package:lets_play_cities/base/game/management.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/base/users.dart';

import 'fake_users.dart';

/// Dictionary where every word not listed in [results] is not found.
class _FakeDictionary extends Fake implements DictionaryService {
  final Map<String, CityResult> results;
  final Stream<String> Function(String city) corrections;

  final checked = <String>[];
  final correctionRequests = <String>[];

  _FakeDictionary({
    this.results = const {},
    Stream<String> Function(String city)? corrections,
  }) : corrections = corrections ?? ((_) => const Stream.empty());

  @override
  Future<CityResult> checkCity(String city) async {
    checked.add(city);
    return results[city] ?? CityResult.cityNotFound;
  }

  @override
  Stream<String> getCorrectionVariants(String city) {
    correctionRequests.add(city);
    return corrections(city);
  }
}

class _FakePreferences extends Fake implements GamePreferences {
  @override
  bool correctionEnabled;

  _FakePreferences({required this.correctionEnabled});
}

Matcher _accepted(String word, User owner) => isA<Accepted>()
    .having((e) => e.word, 'word', word)
    .having((e) => e.owner, 'owner', same(owner));

Matcher _corrections(Set<String> corrections) =>
    isA<Corrections>().having((e) => e.corrections, 'corrections', corrections);

void main() {
  late Player player;

  setUp(() => player = newPlayer());

  Future<List<GameEvent>> check(DictionaryService dictionary, String word) =>
      DatabaseChecker(dictionary).process(RawWordEvent(word, player)).toList();

  group('dictionary lookup', () {
    test('accepts a word found in the dictionary for its owner', () async {
      final dictionary = _FakeDictionary(results: {'москва': CityResult.ok});

      expect(await check(dictionary, 'москва'), [_accepted('москва', player)]);
      expect(dictionary.correctionRequests, isEmpty);
    });

    test('rejects a word that was already used in this game', () async {
      final dictionary = _FakeDictionary(
        results: {'москва': CityResult.alreadyUsed},
      );

      expect(await check(dictionary, 'москва'), [
        isA<AlreadyUsed>().having((e) => e.word, 'word', 'москва'),
      ]);
      expect(dictionary.correctionRequests, isEmpty);
    });

    test('retries a word with spaces as a hyphenated name', () async {
      final dictionary = _FakeDictionary(
        results: {'нижний-новгород': CityResult.ok},
      );

      expect(await check(dictionary, 'нижний новгород'), [
        _accepted('нижний-новгород', player),
      ]);
      expect(dictionary.checked, ['нижний новгород', 'нижний-новгород']);
    });

    test('reports the hyphenated name when it was already used', () async {
      final dictionary = _FakeDictionary(
        results: {'нижний-новгород': CityResult.alreadyUsed},
      );

      expect(await check(dictionary, 'нижний новгород'), [
        isA<AlreadyUsed>().having((e) => e.word, 'word', 'нижний-новгород'),
      ]);
    });

    test('passes events other than words through unchecked', () async {
      // Trusted words arrive here already converted to Accepted.
      final dictionary = _FakeDictionary();
      final accepted = Accepted('москва', FakeOpponent());

      final result = await DatabaseChecker(dictionary)
          .process(accepted)
          .toList();

      expect(result, [same(accepted)]);
      expect(dictionary.checked, isEmpty);
    });
  });

  group('corrections', () {
    test('are not looked up for words of three letters or fewer', () async {
      final dictionary = _FakeDictionary(
        corrections: (_) => Stream.value('уфа'),
      );

      expect(await check(dictionary, 'уфв'), [
        isA<NotFound>().having((e) => e.word, 'word', 'уфв'),
      ]);
      expect(dictionary.correctionRequests, isEmpty);
    });

    test('are looked up for a four-letter word', () async {
      final dictionary = _FakeDictionary();

      expect(await check(dictionary, 'омск'), [
        isA<NotFound>().having((e) => e.word, 'word', 'омск'),
      ]);
      expect(dictionary.correctionRequests, ['омск']);
    });

    test('when disabled in settings, an unknown word is not found', () async {
      final source = _FakeDictionary(
        corrections: (_) => Stream.value('москва'),
      );
      final dictionary = DictionaryDecorator(
        source,
        _FakePreferences(correctionEnabled: false),
      );

      expect(await check(dictionary, 'масква'), [
        isA<NotFound>().having((e) => e.word, 'word', 'масква'),
      ]);
      expect(source.correctionRequests, isEmpty);
    });

    test('a single correction is offered and then accepted', () async {
      final dictionary = _FakeDictionary(
        corrections: (_) => Stream.value('москва'),
      );

      expect(await check(dictionary, 'масква'), [
        _corrections({'москва'}),
        _accepted('москва', player),
      ]);
    });

    test('several corrections are offered for the user to choose', () async {
      final dictionary = _FakeDictionary(
        corrections: (_) => Stream.fromIterable(['москва', 'моска']),
      );

      final result = await check(dictionary, 'масква');

      expect(result, [isA<Corrections>(), isA<Corrections>()]);
      expect(
        (result.last as Corrections).corrections,
        unorderedEquals(['москва', 'моска']),
      );
    });

    test('each offer holds every correction found so far', () async {
      final source = StreamController<String>();
      final dictionary = _FakeDictionary(corrections: (_) => source.stream);
      final offered = <Set<String>>[];
      final done = Completer<void>();
      DatabaseChecker(dictionary)
          .process(RawWordEvent('масква', player))
          .listen(
            (event) => offered.add({...(event as Corrections).corrections}),
            onDone: done.complete,
          );

      source.add('москва');
      await pumpEventQueue();
      expect(offered, [
        {'москва'},
      ]);

      source.add('моска');
      await pumpEventQueue();
      expect(offered, [
        {'москва'},
        {'москва', 'моска'},
      ]);

      await source.close();
      await done.future;
      expect(offered, hasLength(2));
    });

    test('all offers share one growing set (pinned)', () async {
      // Pinned on purpose: the result bar only shows the latest offer, so
      // sharing is harmless today. An earlier Corrections event is not a
      // snapshot; if events become immutable copies, update this test.
      final dictionary = _FakeDictionary(
        corrections: (_) => Stream.fromIterable(['москва', 'моска']),
      );

      final result = (await check(
        dictionary,
        'масква',
      )).cast<Corrections>().toList();

      expect(result.first.corrections, same(result.last.corrections));
      expect(result.first.corrections, {'москва', 'моска'});
    });
  });

  group('a correction search that never finishes', () {
    /// Collects what [DatabaseChecker] emits for 'масква' while the
    /// dictionary's correction search is [search].
    ({List<GameEvent> events, bool Function() isDone}) startCheck(
      StreamController<String> search,
    ) {
      final dictionary = _FakeDictionary(corrections: (_) => search.stream);
      final events = <GameEvent>[];
      var done = false;
      DatabaseChecker(dictionary)
          .process(RawWordEvent('масква', player))
          .listen(events.add, onDone: () => done = true);
      return (events: events, isDone: () => done);
    }

    /// The search must be cancellable with a Future of the fake zone, like
    /// an async* generator: a plain controller completes its cancel in the
    /// root zone, which fake_async never flushes, so the check would hang.
    StreamController<String> endlessSearch({void Function()? onCancel}) =>
        StreamController<String>(onCancel: () async => onCancel?.call());

    test(
      'ends with NotFound 3 seconds after it started if it found nothing',
      () {
        fakeAsync((async) {
          final check = startCheck(endlessSearch());

          async.elapse(const Duration(milliseconds: 2999));
          expect(check.isDone(), isFalse);
          expect(check.events, isEmpty);

          async.elapse(const Duration(milliseconds: 1));
          expect(check.isDone(), isTrue);
          expect(check.events, [
            isA<NotFound>().having((e) => e.word, 'word', 'масква'),
          ]);
        });
      },
    );

    test('accepts its only correction 3 seconds later and cancels it', () {
      fakeAsync((async) {
        var searchCancelled = false;
        final search = endlessSearch(onCancel: () => searchCancelled = true);
        final check = startCheck(search);
        async.flushMicrotasks();
        search.add('москва');

        async.elapse(const Duration(milliseconds: 2999));
        expect(check.isDone(), isFalse);
        expect(check.events, [
          _corrections({'москва'}),
        ]);
        expect(searchCancelled, isFalse);

        async.elapse(const Duration(milliseconds: 1));
        expect(check.isDone(), isTrue);
        expect(check.events, [
          _corrections({'москва'}),
          _accepted('москва', player),
        ]);
        expect(searchCancelled, isTrue);
      });
    });

    test('waits another 3 seconds after every new correction', () {
      fakeAsync((async) {
        final search = endlessSearch();
        final check = startCheck(search);
        async.flushMicrotasks();
        search.add('москва');
        async.elapse(const Duration(seconds: 2));
        search.add('моска');

        async.elapse(const Duration(milliseconds: 2999));
        expect(check.isDone(), isFalse);

        async.elapse(const Duration(milliseconds: 1));
        expect(check.isDone(), isTrue);
        // Two corrections: the user has to pick one, nothing is accepted.
        expect(check.events, [isA<Corrections>(), isA<Corrections>()]);
      });
    });
  });
}
