import 'dart:async';

import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/game/player/users_list.dart';
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

  onStart();

  sendEvent(OutputEvent event) {
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
    //TODO: Temp code
    if (event is OutputWordEvent) {
      _streamController.sink.add(InputWordEvent(
          word: event.word,
          wordResult: WordResult.ACCEPTED,
          ownerId: event.owner.id));
    }
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
  final UsersList usersList;

  StubEventChannel(this.usersList);

  @override
  onStart() {
    sendEvent(OnUserSwitchedEvent(usersList.first.id));
  }

  @override
  Stream<int> buildTimerStream() =>
      Stream.periodic(Duration(seconds: 1)).take(92);

  @override
  Stream<InputEvent> provideInputEvents() async* {}
}
