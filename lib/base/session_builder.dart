import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/game/management/events_channel.dart';
import 'package:lets_play_cities/base/game/management/result_with_city.dart';
import 'package:lets_play_cities/base/game/player/player.dart';
import 'package:lets_play_cities/base/game/word_checking_result.dart';
import 'package:lets_play_cities/utils/string_utils.dart';

import 'game/player/user.dart';

class GameSession {
  final List<User> users;
  final AbstractEventChannel eventChannel;

  GameSession({this.users, this.eventChannel}) {
    // Setup users positions
    for (int i = 0; i < users.length; i++)
      users[i].position = Position.values[i];
  }

  /// Keeps index of current user
  int _currentUserIndex = 0;

  /// Returns index of next [User] in array [users]. Index looped in range 0..users.size.
  int get nextIndex => (_currentUserIndex + 1) % users.length;

  /// Returns current [User]
  User get currentUser => users[_currentUserIndex];

  /// Returns previous [User] in queue
  User get prevUser => users[_floorMod(_currentUserIndex - 1, users.length)];

  static int _floorMod(num x, num y) => ((x % y) + y) % y;

  /// Last accepted word
  String _lastAcceptedWord = "";

  /// Dispatches user input to the first [Player] in users list
  Stream<WordCheckingResult> deliverUserInput(String userInput) =>
      users.whereType<Player>().single.onUserInput(userInput);

  /// Call to start game turn for current user.
  Stream<ResultWithCity> makeMoveForCurrentUser() async* {
    var lastSuitableChar =
        _lastAcceptedWord[indexOfLastSuitableChar(_lastAcceptedWord)];

    await for (var moveResult in currentUser.onMakeMove(lastSuitableChar)) {
      if (moveResult.isSuccessful()) {
        _lastAcceptedWord = moveResult.city;
        _currentUserIndex = nextIndex;
      }
      yield moveResult;
    }
  }
}
