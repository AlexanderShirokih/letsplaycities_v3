import 'dart:async';

class _SubscriptionData<T> {
  final Stream<T> source;
  final StreamSubscription<T> subscription;
  bool isClosed = false;

  _SubscriptionData(this.source, this.subscription);

  void cancelSubscription() {
    if (!isClosed) {
      isClosed = true;
      subscription.cancel();
    }
  }
}

class _MergeStreamController<T> {
  final StreamController<T> _controller = StreamController<T>();
  int workingStreamsCount = 0;

  _MergeStreamController(List<Stream<T>> sources, bool Function(T) predicate) {
    workingStreamsCount = sources.length;
    // Assign listeners to all source streams
    final List<_SubscriptionData<T>> subscriptions = sources
        .map((source) => _SubscriptionData(source, source.listen(null)))
        .toList(growable: false);

    void cancelAll() {
      subscriptions.forEach((sub) {
        sub.cancelSubscription();
      });
    }

    subscriptions.forEach((subsData) {
      subsData.subscription.onData((data) {
        if (!predicate(data)) {
          workingStreamsCount = 0;
          _controller.close();
          cancelAll();
        } else if (!_controller.isClosed) _controller.add(data);
      });

      subsData.subscription.onDone(() {
        if (--workingStreamsCount <= 0) _controller.close();
        subsData.cancelSubscription();
      });
    });
  }
}

/// Merges [sources] streams into a single stream channel
/// Stream closes when the first [source] stream emits event which is not satisfying predicate
/// or all streams done its work.
Stream<T> mergeStreamsWhile<T>(
        List<Stream<T>> sources, bool Function(T) takeWhile) =>
    _MergeStreamController(sources, takeWhile)._controller.stream;
