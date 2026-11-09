import 'package:lets_play_cities/base/game/management/word_checking_result.dart';
import 'package:lets_play_cities/base/game/player/user.dart';
import 'package:meta/meta.dart';

/// Base sealed class for all events
@immutable
abstract class GameEvent {
  const GameEvent();
}

/// An event emitted when user enters a new word
/// Should be converted by event processors to [WordCheckingResult] kind.
class RawWordEvent extends GameEvent {
  final User owner;
  final String word;

  const RawWordEvent(this.word, this.owner);
}

/// An event emitted when new input message entered
class MessageEvent extends GameEvent {
  final String message;
  final User owner;

  const MessageEvent(this.message, this.owner);
}

/// An event that emits every time when current user changed
class OnUserSwitchedEvent extends GameEvent {
  final List<User> allUsers;
  final User nextUser;

  const OnUserSwitchedEvent(this.nextUser, this.allUsers);
}

/// An event that used to signal FirstLetterChecker a new first char
class OnFirstCharChanged extends GameEvent {
  final String firstChar;

  const OnFirstCharChanged(this.firstChar);
}

/// Describes reason why users move was ended.
enum MoveFinishType {
  completed,
  timeout,
  disconnected,
  surrender,

  /// The account signed in on another device and the server ended the game
  replaced,

  /// The route reached its last move
  routeCompleted,
}

/// Emits when users move ended (completed or failed)
class OnMoveFinished extends GameEvent {
  /// Move finish result
  final MoveFinishType endType;

  /// Who's finishes the move
  final User finishRequester;

  const OnMoveFinished(this.endType, this.finishRequester);
}

/// Emits when the time of [owner] ran out and the move passed to the next
/// user
class MoveSkipped extends GameEvent {
  final User owner;

  const MoveSkipped(this.owner);
}

/// Asks the server of a network game to let [owner] leave: the server ends
/// the game with the loss of [owner]
class LeaveRequested extends GameEvent {
  final User owner;

  const LeaveRequested(this.owner);
}

/// An event that represents game timer ticks
class TimeEvent extends GameEvent {
  /// Seconds left for the current move.
  final int secondsLeft;

  const TimeEvent(this.secondsLeft);
}
