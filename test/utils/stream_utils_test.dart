import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/utils/stream_utils.dart';

void main() {
  group('mergeStreamsWhile', () {
    late StreamController<int> first;
    late StreamController<int> second;
    late List<String> cancelled;

    setUp(() {
      cancelled = [];
      // Synchronous, so events reach the merged stream in the order added.
      first = StreamController<int>(
        sync: true,
        onCancel: () => cancelled.add('first'),
      );
      second = StreamController<int>(
        sync: true,
        onCancel: () => cancelled.add('second'),
      );
    });

    test('ends after the first rejected event and stops the sources', () async {
      final merged = mergeStreamsWhile([first.stream, second.stream], (e) {
        return e >= 0;
      });

      first.add(1);
      second.add(2);
      second.add(-1);
      first.add(3);

      expect(await merged.toList(), [1, 2, -1]);
      expect(cancelled, unorderedEquals(['first', 'second']));
    });

    test('ends when all sources are done', () async {
      final merged = mergeStreamsWhile([
        Stream.fromIterable([1, 2]),
        Stream.fromIterable([3]),
      ], (_) => true);

      expect(await merged.toList(), unorderedEquals([1, 2, 3]));
    });

    test('passes a source error on, then ends and stops the sources', () async {
      final merged = mergeStreamsWhile([
        first.stream,
        second.stream,
      ], (_) => true);
      final received = <Object>[];
      final done = Completer<void>();
      merged.listen(
        received.add,
        onError: (Object error) => received.add('error: $error'),
        onDone: done.complete,
      );

      first.add(1);
      second.addError(StateError('broken'));
      first.add(2);

      await done.future.timeout(const Duration(milliseconds: 100));
      expect(received, [1, 'error: Bad state: broken']);
      expect(cancelled, unorderedEquals(['first', 'second']));
    });

    test('stops the sources when the listener cancels', () async {
      final subscription = mergeStreamsWhile([
        first.stream,
        second.stream,
      ], (_) => true).listen(null);

      await subscription.cancel();

      expect(cancelled, unorderedEquals(['first', 'second']));
    });
  });
}
