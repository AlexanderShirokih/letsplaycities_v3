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

  /// Called when the game starts
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
      print("Hit!");
      _streamController.sink.add(InputWordEvent(
          word: event.word,
          wordResult: WordResult.ACCEPTED,
          ownerId: event.owner.id));
      _streamController.sink
          .add(OnUserSwitchedEvent(event.owner.id == -2 ? -1 : -2));
    }
  }

  /// Emits game countdown values in seconds
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
      Stream<int>.periodic(Duration(seconds: 1), (i) => 92 - i).take(92);

  @override
  Stream<InputEvent> provideInputEvents() async* {}
}
