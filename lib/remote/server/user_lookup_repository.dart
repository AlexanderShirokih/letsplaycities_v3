import 'package:lets_play_cities/remote/auth.dart';

/// Authorized user registry
abstract class UserLookupRepository {
  /// Lookups previously added user by its [Credential]s.
  /// Returns [ProfileInfo] if user was found or `null` if not.
  ProfileInfo? getUser(Credential d);

  /// Adds users [ProfileInfo] to registry
  void addUser(ProfileInfo profile);

  /// Clears all users
  void clear();
}

/// [UserLookupRepository] implementation
class UserLookupRepositoryImpl implements UserLookupRepository {
  final List<ProfileInfo> _authorizedUsers = [];

  @override
  ProfileInfo? getUser(Credential d) {
    try {
      return _authorizedUsers
          .where((element) => element.userId == d.userId)
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
