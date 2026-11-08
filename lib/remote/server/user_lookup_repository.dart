import 'package:lets_play_cities/remote/auth.dart';

/// Authorized user registry
abstract class UserLookupRepository {
  // The LAN server never checked the access hash; replaced in protocol v1 task 6
  /// Lookups previously added user by its [userId].
  /// Returns [ProfileInfo] if user was found or `null` if not.
  ProfileInfo? getUser(int userId);

  /// Adds users [ProfileInfo] to registry
  void addUser(ProfileInfo profile);

  /// Clears all users
  void clear();
}

/// [UserLookupRepository] implementation
class UserLookupRepositoryImpl implements UserLookupRepository {
  final List<ProfileInfo> _authorizedUsers = [];

  @override
  ProfileInfo? getUser(int userId) {
    try {
      return _authorizedUsers
          .where((element) => element.userId == userId)
          .first;
    } on StateError {
      return null;
    }
  }

  @override
  void addUser(ProfileInfo profile) => _authorizedUsers.add(profile);

  @override
  void clear() => _authorizedUsers.clear();
}
