import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/utils/debouncer.dart';

const delay = Duration(milliseconds: 1000);
const ms = Duration(milliseconds: 1);

void main() {
  // Every Debouncer is created inside fakeAsync: it reads the clock in its
  // constructor, and its timers must belong to the fake zone.

  test('a call right after creation is deferred by the full delay', () {
    fakeAsync((async) {
      final debouncer = Debouncer(delay);
      final runs = <String>[];

      debouncer.run(() => runs.add('a'));
      expect(runs, isEmpty);

      async.elapse(delay - ms);
      expect(runs, isEmpty);

      async.elapse(ms);
      expect(runs, ['a']);
    });
  });

  test('a call more than the delay after the last run runs at once', () {
    fakeAsync((async) {
      final debouncer = Debouncer(delay);
      final runs = <String>[];

      async.elapse(delay + ms);
      debouncer.run(() => runs.add('a'));
      expect(runs, ['a'], reason: 'ran synchronously, without a timer');

      async.elapse(delay + ms);
      debouncer.run(() => runs.add('b'));
      expect(runs, ['a', 'b']);
      expect(async.pendingTimers, isEmpty);
    });
  });

  test('a call exactly one delay after the last run is still deferred', () {
    fakeAsync((async) {
      final debouncer = Debouncer(delay);
      final runs = <String>[];

      async.elapse(delay);
      debouncer.run(() => runs.add('a'));
      expect(runs, isEmpty);

      async.elapse(delay);
      expect(runs, ['a']);
    });
  });

  test('a negative offset moves the last run into the past', () {
    fakeAsync((async) {
      final debouncer = Debouncer(delay, offset: -(delay + ms));
      final runs = <String>[];

      debouncer.run(() => runs.add('a'));
      expect(runs, ['a']);
    });
  });

  test('a deferred call waits a full delay, not the rest of the window', () {
    fakeAsync((async) {
      final debouncer = Debouncer(delay);
      final runs = <String>[];

      // 900 ms into the window: only 100 ms of it are left.
      async.elapse(const Duration(milliseconds: 900));
      debouncer.run(() => runs.add('a'));

      async.elapse(delay - ms);
      expect(runs, isEmpty);
      async.elapse(ms);
      expect(runs, ['a']);
    });
  });

  test('only the latest of several calls within the window runs', () {
    fakeAsync((async) {
      final debouncer = Debouncer(delay);
      final runs = <String>[];

      debouncer.run(() => runs.add('a'));
      async.elapse(const Duration(milliseconds: 300));
      debouncer.run(() => runs.add('b'));
      async.elapse(const Duration(milliseconds: 300));
      debouncer.run(() => runs.add('c'));

      // 'b' would have fired here had 'c' not replaced it.
      async.elapse(const Duration(milliseconds: 700));
      expect(runs, isEmpty);

      async.elapse(const Duration(milliseconds: 300));
      expect(runs, ['c']);

      async.elapse(delay * 5);
      expect(runs, ['c']);
    });
  });

  test('cancel() drops the pending call', () {
    fakeAsync((async) {
      final debouncer = Debouncer(delay);
      final runs = <String>[];

      debouncer.run(() => runs.add('a'));
      debouncer.cancel();

      async.elapse(delay * 5);
      expect(runs, isEmpty);
      expect(async.pendingTimers, isEmpty);
    });
  });

  test('a deferred run restarts the delay window', () {
    // Regression: the deferred run did not record its time, so a call right
    // after it compared against the older run and went through at once.
    // GameSessionRepository then sent two words 100 ms apart despite its
    // 1 s throttle.
    fakeAsync((async) {
      final debouncer = Debouncer(delay);
      final runs = <String>[];

      async.elapse(delay + ms);
      debouncer.run(() => runs.add('a'));
      expect(runs, ['a']);

      async.elapse(const Duration(milliseconds: 500));
      debouncer.run(() => runs.add('b'));
      async.elapse(delay);
      expect(runs, ['a', 'b'], reason: 'b deferred until 1500 ms after a');

      async.elapse(const Duration(milliseconds: 100));
      debouncer.run(() => runs.add('c'));
      expect(runs, ['a', 'b'], reason: 'c comes 100 ms after b');

      async.elapse(delay);
      expect(runs, ['a', 'b', 'c']);
    });
  });
}
