import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/dictionary.dart';
import 'package:lets_play_cities/base/game/game_mode.dart';
import 'package:lets_play_cities/base/users.dart';

/// Manages user queue. Defines users list,
/// who would make next move and its order.
class UsersList {
  final List<User> _users;

  UsersList(this._users) {
    // Setup users positions
    for (int i = 0; i < _users.length; i++)
      _users[i].position = Position.values[i];
  }

  /// Keeps index of current user
  int _currentUserIndex = 0;

  /// Returns current [User]
  User get current => _users[_currentUserIndex];

  /// Returns first user in the queue
  User get first => _users.first;

  /// Returns next user in the queue.
  User get next => _users[(_currentUserIndex + 1) % _users.length];

  /// Sets the current user to [user]
  set current(User user) => _currentUserIndex = _users.indexOf(user);

  /// Returns user attached to the [position]
  /// Throws [StateError] if there is no user attached to the [position].
  User getUserByPosition(Position position) =>
      _users.firstWhere((element) => element.position == position);

  /// Returns user by this ID in account data
  User getUserById(int userId) =>
      _users.firstWhere((element) => userId == element.id);

  /// Returns current user in users list as [Player] instance
  /// or null if current user is not [Player].
  Player get currentPlayer {
    try {
      return _users
          .where((element) => element == current)
          .whereType<Player>()
          .single;
    } on StateError {
      return null;
    }
  }

  /// Switches current user to the next user in queue
  void switchToNext() {
    current = next;
  }

  factory UsersList.forGameMode(
      GameMode gameMode, DictionaryService dictionaryService) {
    switch (gameMode) {
      case GameMode.PlayerVsAndroid:
        return _buildPvAList(dictionaryService);
      case GameMode.PlayerVsPlayer:
        return _buildPvPList();
      default:
        throw ("Unsupported game mode!");
    }
  }

  static UsersList _buildPvAList(DictionaryService dictionary) => UsersList([
        Player(
          PlayerData(
            name: "Игрок",
            picture: PlaceholderPictureSource(),
          ),
        ),
        Android(dictionary, "Андроид"),
      ]);

  static UsersList _buildPvPList() => UsersList([
        Player(
          PlayerData(
            name: "Игрок 1",
            picture: PlaceholderPictureSource(),
          ),
        ),
        Player(
          PlayerData(
            name: "Игрок 2",
            picture: PlaceholderPictureSource(),
          ),
        ),
      ]);
}
