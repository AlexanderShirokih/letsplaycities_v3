import 'input_events.dart';
import 'output_events.dart';

abstract class AbstractEventChannel {

  Stream<InputEvent> getInputEvents() => Stream.empty();

  sendToChannel(OutputEvent outputEvent) async {}

}
