import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

/// Events are processed one by one in the order they were added; an error in
/// a mapper is reported through [onError] without stopping the bloc.
mixin SequentialEventMapping<E, S> on Bloc<E, S> {
  /// Registers [mapper] as the only handler for all events of type [E].
  ///
  /// Call it once from the constructor.
  void mapEventsSequentially(Stream<S> Function(E event) mapper) {
    on<E>((event, emit) async {
      try {
        await emit.forEach<S>(mapper(event), onData: (state) => state);
      } catch (error, stackTrace) {
        addError(error, stackTrace);
      }
    }, transformer: (events, eventMapper) => events.asyncExpand(eventMapper));
  }
}
