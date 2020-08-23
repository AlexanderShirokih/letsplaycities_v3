import 'dart:async';

import 'package:lets_play_cities/utils/string_utils.dart';
import 'package:meta/meta.dart';

import 'input_events.dart';
import 'output_events.dart';

abstract class AbstractEventChannel {
  final StreamController<InputEvent> _streamController =
      StreamController.broadcast();

  StreamSubscription _timerSubs;

  Stream<InputEvent> getInputEvents() => _streamController.stream;

  @protected
  Stream<InputEvent> provideInputEvents();

  Future sendEvent(OutputEvent event) {
    // Redirect control events to input
    if (event is ControlEvent) {
      _streamController.sink.add(event);

      if (event is OnUserSwitchedEvent) {
        // Start game timer when user turn begins
        _timerSubs?.cancel();
        _timerSubs = buildTimerStream().listen((time) {
          _streamController.sink.add(TimeEvent(timeFormat(time)));
        });
      }
    }

    return null;
  }

  @protected
  Stream<int> buildTimerStream();

  AbstractEventChannel() {
    _streamController.addStream(provideInputEvents());
  }

  dispose() {
    _streamController.close();
  }
}

class StubEventChannel extends AbstractEventChannel {
  @override
  Stream<int> buildTimerStream() =>
      Stream.periodic(Duration(seconds: 1)).take(92);

  @override
  Stream<InputEvent> provideInputEvents() async* {
    await Future.delayed(Duration(milliseconds: 500));

    for (int i = 0; i < 10; i++) {
      await Future.delayed(Duration(milliseconds: 2000));
      // Yield Players or Android word

      yield OnUserSwitchedEvent(i % 2 != 0 ? -1 : -2);
      yield InputWordEvent("Hello World #$i", i % 2 == 0 ? -1 : -2);
    }
  }

}
