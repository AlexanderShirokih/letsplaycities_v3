import 'dart:async';

import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/management.dart';
import 'package:lets_play_cities/base/users.dart';
import 'package:lets_play_cities/base/game/word_checking_result.dart';
import 'package:lets_play_cities/utils/string_utils.dart';
import 'package:meta/meta.dart';

import 'game/player/user.dart';

class GameSession {
  final List<User> users;
  final AbstractEventChannel eventChannel;

  GameSession({@required this.users, @required this.eventChannel}) {
    // Setup users positions
    for (int i = 0; i < users.length; i++)
      users[i].position = Position.values[i];
  }

  /// True until game finishes
  bool _gameRunning = true;

  /// Keeps index of current user
  int _currentUserIndex = 0;

  /// Returns index of next [User] in array [users]. Index looped in range 0..users.size.
  int get nextIndex => (_currentUserIndex + 1) % users.length;

  /// Returns current [User]
  User get currentUser => users[_currentUserIndex];

  /// Returns previous [User] in queue
  User get prevUser => users[_floorMod(_currentUserIndex - 1, users.length)];

  static int _floorMod(num x, num y) => ((x % y) + y) % y;

  /// Returns user attached to the [position]
  /// Throws [StateError] if there is no user attached to the [position].
  User getUserByPosition(Position position) =>
      users.firstWhere((element) => element.position == position);

  /// Returns user by this ID in account data
  User getUserById(int userId) =>
      users.firstWhere((element) => userId == element.id);

  /// Last accepted word
  String _lastAcceptedWord = "";

  /// Dispatches user input to the first [Player] in users list
  Stream<WordCheckingResult> deliverUserInput(String userInput) =>
      users.whereType<Player>().single.onUserInput(userInput);

  /// Call to start game turn for current user.
  Future<ResultWithCity> makeMoveForCurrentUser() async {
    var lastSuitableChar =
        _lastAcceptedWord[indexOfLastSuitableChar(_lastAcceptedWord)];

    await for (var moveResult in currentUser.onMakeMove(lastSuitableChar)) {
      if (moveResult.isSuccessful()) {
        _lastAcceptedWord = moveResult.city;
        _currentUserIndex = nextIndex;
      }
      return moveResult;
    }

    return null;
  }

  /// Completes all user moves
  Future doAllMoves() async {
    while (_gameRunning) {
      eventChannel.sendEvent(OnUserSwitchedEvent(currentUser.id));
      await makeMoveForCurrentUser();
    }
  }

}
