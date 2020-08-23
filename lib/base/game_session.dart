import 'dart:async';

import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/management.dart';
import 'package:lets_play_cities/base/users.dart';
import 'package:lets_play_cities/base/game/word_checking_result.dart';
import 'package:lets_play_cities/utils/string_utils.dart';
import 'package:meta/meta.dart';

import 'game/player/user.dart';

class GameSession {
  final UsersList usersList;
  final AbstractEventChannel eventChannel;

  StreamSubscription _eventChannelSubscription;

  GameSession({@required this.usersList, @required this.eventChannel})
      : assert(usersList != null),
        assert(eventChannel != null) {
    _eventChannelSubscription =
        eventChannel.getInputEvents().listen(_handleInputEvents);
  }

  /// Called when the game starts
  start() {
    eventChannel.onStart();
  }

  /// Returns user attached to the [position]
  /// Throws [StateError] if there is no user attached to the [position].
  User getUserByPosition(Position position) =>
      usersList.getUserByPosition(position);

  /// Returns user by this ID in account data
  User getUserById(int userId) => usersList.getUserById(userId);

  /// Last accepted word
  String _lastAcceptedWord = "";

  /// Dispatches user input to the first [Player] in users list
  Stream<WordCheckingResult> deliverUserInput(String userInput) =>
      usersList.requirePlayer.onUserInput(userInput);

  /// Call to start game turn for current user.
  Future _makeMoveForCurrentUser() async {
    var lastSuitableChar =
        _lastAcceptedWord[indexOfLastSuitableChar(_lastAcceptedWord)];

    final city = await usersList.current.onCreateWord(lastSuitableChar);
    eventChannel.sendEvent(OutputWordEvent(city.city, city.owner));
  }

  _handleInputEvents(InputEvent event) async {
    if (event is OnUserSwitchedEvent) {
      usersList.current = usersList.getUserById(event.nextUserId);
      await _makeMoveForCurrentUser();
    } else if (event is InputWordEvent && event.wordResult.isSuccessful()) {
      _lastAcceptedWord = event.word;
    }
  }

  Future dispose() async {
    await _eventChannelSubscription.cancel();
  }
}
