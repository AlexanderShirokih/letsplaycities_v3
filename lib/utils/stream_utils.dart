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
    final subscriptions = sources
        .map((source) => _SubscriptionData(source, source.listen(null)))
        .toList(growable: false);

    void cancelAll() {
      for (var sub in subscriptions) {
        sub.cancelSubscription();
      }
    }

    // Stop the sources when the merged stream is no longer listened to.
    _controller.onCancel = cancelAll;

    for (var subsData in subscriptions) {
      subsData.subscription.onData((data) {
        if (_controller.isClosed) return;
        if (!predicate(data)) {
          // Little trick: emit latest rejected event
          _controller.add(data);
          workingStreamsCount = 0;
          _controller.close();
          cancelAll();
        } else {
          _controller.add(data);
        }
      });

      subsData.subscription.onError((Object error, StackTrace stackTrace) {
        if (_controller.isClosed) return;
        _controller.addError(error, stackTrace);
        workingStreamsCount = 0;
        _controller.close();
        cancelAll();
      });

      subsData.subscription.onDone(() {
        if (--workingStreamsCount <= 0) _controller.close();
        subsData.cancelSubscription();
      });
    }
  }
}

/// Merges [sources] streams into a single stream channel
/// Stream closes when the first [source] stream emits event which is not satisfying predicate
/// or all streams done its work.
/// The first error of any source is passed on and closes the stream.
/// All sources are cancelled when the stream closes or its listener cancels.
Stream<T> mergeStreamsWhile<T>(
  List<Stream<T>> sources,
  bool Function(T) takeWhile,
) => _MergeStreamController(sources, takeWhile)._controller.stream;
