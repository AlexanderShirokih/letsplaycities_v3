import 'package:lets_play_cities/base/game/player/user.dart';

/// Interface that used for comparing users
class UserIdentity {
  /// Compares this user identity with other [user].
  /// Returns `true` is this user identity considers the same, `false` otherwise.
  bool isTheSameUser(User user) => false;
}

/// Compares two users by its userId's
class UserIdIdentity implements UserIdentity {
  final int userId;

  UserIdIdentity(this.userId);

  UserIdIdentity.fromUser(User user)
      : this(user?.accountInfo?.credential?.userId ?? -1);

  @override
  bool isTheSameUser(User user) =>
      userId == user?.accountInfo?.credential?.userId ?? -1;
}
