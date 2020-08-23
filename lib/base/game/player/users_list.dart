import 'package:lets_play_cities/base/data.dart';
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

  /// Returns index of next [User] in array [_users]. Index looped in range 0..users.size.
  int get _nextIndex => (_currentUserIndex + 1) % _users.length;

  /// Returns current [User]
  User get current => _users[_currentUserIndex];

  /// Returns first user in the queue
  User get first => _users.first;

  /// Sets the current user to [user]
  set current(User user) => _currentUserIndex = _users.indexOf(user);

  /// Returns previous [User] in queue
  User get prev => _users[_floorMod(_currentUserIndex - 1, _users.length)];

  /// Returns the next user in queue.
  User get next => _users[_nextIndex];

  static int _floorMod(num x, num y) => ((x % y) + y) % y;

  /// Returns user attached to the [position]
  /// Throws [StateError] if there is no user attached to the [position].
  User getUserByPosition(Position position) =>
      _users.firstWhere((element) => element.position == position);

  /// Returns user by this ID in account data
  User getUserById(int userId) =>
      _users.firstWhere((element) => userId == element.id);

  /// Returns [Player] instance in users list
  /// or throws an error if user wasn't found.
  Player get requirePlayer => _users.whereType<Player>().single;
}
