import 'package:lets_play_cities/base/game/player/user.dart';
import 'package:meta/meta.dart';

/// Base sealed class for all events
@immutable
abstract class GameEvent {}

/// An event emitted when user enters a new word
/// Should be converted by event processors to [WordCheckingResult] kind.
class RawWordEvent extends GameEvent {
  final User owner;
  final String word;

  RawWordEvent(this.word, this.owner);
}

/// An event emitted when new input message entered
class MessageEvent extends GameEvent {
  final String message;
  final User owner;

  MessageEvent(this.message, this.owner);
}

/// An event that emits every time when current user changed
class OnUserSwitchedEvent extends GameEvent {
  final User nextUser;

  OnUserSwitchedEvent(this.nextUser);
}

/// An event that used to signal FirstLetterChecker a new first char
class OnFirstCharChanged extends GameEvent {
  final String firstChar;

  OnFirstCharChanged(this.firstChar);
}

/// Describes reason why users move was ended.
enum MoveFinishType { Completed, Timeout, Disconnected }

/// Emits when users move ended (completed or failed)
class OnMoveFinished extends GameEvent {
  final int moveTime;
  final MoveFinishType endType;

  OnMoveFinished(this.moveTime, this.endType);
}

/// An event that represents game timer ticks
class TimeEvent extends GameEvent {
  final String currentTime;

  TimeEvent(this.currentTime);
}
