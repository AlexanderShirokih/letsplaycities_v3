import 'input_events.dart';
import 'output_events.dart';

abstract class AbstractEventChannel {
  Stream<InputEvent> getInputEvents();

  Future sendToChannel(OutputEvent outputEvent);
}

class StubEventChannel extends AbstractEventChannel {
  @override
  Stream<InputEvent> getInputEvents() async* {
    for (int i = 0; i < 10; i++) {
      await Future.delayed(Duration(milliseconds: 2000));
      // Yield Players or Android word
      yield InputWordEvent("Hello World #$i", i % 2 == 0 ? -1 : -2);
    }
  }

  @override
  Future sendToChannel(OutputEvent outputEvent) {
    // TODO: implement sendToChannel
    throw UnimplementedError();
  }
}
