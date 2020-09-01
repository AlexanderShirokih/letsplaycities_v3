import 'dart:async';

/// Used to debounce function call.
/// That means [runnable] function will be called at most once per [delay].
class Debouncer {
  int _lastTime;
  Timer _timer;
  Duration delay;

  Debouncer(this.delay, {Duration offset})
      : _lastTime = DateTime.now().millisecondsSinceEpoch +
            (offset?.inMilliseconds ?? 0);

  run(Function runnable) {
    _timer?.cancel();

    final current = DateTime.now().millisecondsSinceEpoch;
    final delta = current - _lastTime;

    // If elapsed time is bigger than [delayInMs] threshold -
    // call function immediately.
    if (delta > delay.inMilliseconds) {
      _lastTime = current;
      runnable();
    } else {
      // Elapsed time is less then [delayInMs] threshold -
      // setup the timer
      _timer = Timer(delay, runnable);
    }
  }

  void cancel() {
    _timer?.cancel();
  }
}
