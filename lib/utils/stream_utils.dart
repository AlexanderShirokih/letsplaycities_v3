import 'dart:async';

/// Merges [sources] streams into single stream channel
/// Stream closes when first [source] stream finishes
Stream<T> mergeByShortest<T>(List<Stream<T>> sources) {
  final controller = StreamController<T>();
  // Assign listeners to all
  final map = sources.asMap().map((i, source) {
    return MapEntry(source, source.listen((event) {
      if (!controller.isClosed) controller.add(event);
    }));
  });

  map.values.forEach((subscription) {
    subscription.onDone(() {
      controller.close();
      map.values.forEach((element) => element.cancel());
    });
  });

  return controller.stream;
}
