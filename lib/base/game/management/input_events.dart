import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/game/management/output_events.dart';
import 'package:meta/meta.dart';

/// Base sealed class for all input events kind
@sealed
abstract class InputEvent {}

/// Base sealed class for input events like message and input city
@sealed
abstract class InputGameEvent extends InputEvent {
  final int ownerId;

  InputGameEvent(this.ownerId);
}

/// An event emitted when new input message received
class InputMessageEvent extends InputGameEvent {
  final String message;

  InputMessageEvent(this.message, int ownerId) : super(ownerId);
}

/// An event emitted when new input word received
class InputWordEvent extends InputGameEvent {
  final WordResult wordResult;
  final String word;

  InputWordEvent({this.word, this.wordResult, int ownerId}) : super(ownerId);
}

/// Base class for all control events like switching users,
@sealed
abstract class ControlEvent implements InputEvent, OutputEvent {}

/// An event that emits every time when current user changed
class OnUserSwitchedEvent extends ControlEvent {
  /// Next user ID
  final int nextUserId;

  OnUserSwitchedEvent(this.nextUserId);
}

/// An event that represents game timer ticks
class TimeEvent extends ControlEvent {
  final String currentTime;

  TimeEvent(this.currentTime);
}
