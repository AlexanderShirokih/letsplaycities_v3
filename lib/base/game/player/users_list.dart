import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/dictionary.dart';
import 'package:lets_play_cities/base/game/game_mode.dart';
import 'package:lets_play_cities/base/game/player/default_player_names.dart';
import 'package:lets_play_cities/base/users.dart';

/// Manages user queue. Defines users list,
/// who would make next move and its order.
class UsersList {
  final List<User> _users;

  UsersList(this._users) {
    // Setup users positions
    for (var i = 0; i < _users.length; i++) {
      _users[i].position = Position.values[i];
    }
  }

  /// Keeps index of current user
  int _currentUserIndex = 0;

  /// Returns current [User]
  User get current => _users[_currentUserIndex];

  /// Returns first user in the queue
  User get first => _users.first;

  /// Returns next user in the queue.
  User get next => _users[(_currentUserIndex + 1) % _users.length];

  /// Returns list of all users
  List<User> get all => _users.toList(growable: false);

  /// Sets the current user to [user]
  set current(User user) => _currentUserIndex = _users.indexOf(user);

  /// Returns user attached to the [position]
  /// Throws [StateError] if there is no user attached to the [position].
  User getUserByPosition(Position position) =>
      _users.firstWhere((element) => element.position == position);

  /// Returns current user in users list as [Player] instance
  /// or `null` if current user is not [Player].
  Player? get currentPlayer {
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

  /// Creates the users of a game on one device, named by [names].
  factory UsersList.forGameMode(
    GameMode gameMode,
    DictionaryDecorator dictionaryService,
    DefaultPlayerNames names,
  ) {
    switch (gameMode) {
      case GameMode.playerVsAndroid:
        return _buildPvAList(dictionaryService, names);
      case GameMode.playerVsPlayer:
        return _buildPvPList(names);
      default:
        throw ('Unsupported game mode!');
    }
  }

  static UsersList _buildPvAList(
    DictionaryDecorator dictionary,
    DefaultPlayerNames names,
  ) => UsersList([
    Player(
      LocalAccountInfo(name: names.player, picture: PlaceholderPictureSource()),
    ),
    Android(dictionary, names.android),
  ]);

  static UsersList _buildPvPList(DefaultPlayerNames names) => UsersList([
    Player(
      LocalAccountInfo(
        name: names.firstPlayer,
        picture: PlaceholderPictureSource(),
      ),
    ),
    Player(
      LocalAccountInfo(
        name: names.secondPlayer,
        picture: PlaceholderPictureSource(),
      ),
    ),
  ]);

  /// Closes all users resources
  Future<void> close() async {
    for (final user in _users) {
      await user.close();
    }
  }
}
