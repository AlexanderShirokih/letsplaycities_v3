import 'package:equatable/equatable.dart';

import 'auth_type.dart';

/// Describes user roles. Legacy of the old protocol: the LAN host and the
/// game messages still use it until they move to protocol v1.
enum Role {
  /// Used when user is banned
  banned('banned'),

  /// Default user state
  regular('ready'),

  /// Used when user has admin privileges
  admin('admin');

  const Role(this.signUpState);

  /// Name of the role in the sign-up response ('state')
  final String signUpState;

  /// Converts the sign-up response 'state' to [Role] value.
  /// Throws a [String] when there is no such role.
  static Role fromSignUpState(String s) {
    for (final value in values) {
      if (value.signUpState == s) {
        return value;
      }
    }
    throw ('Unknown UserRole: $s');
  }
}

/// Friendship status between two users
enum FriendshipStatus {
  /// Users aren't friends
  notFriends('notFriends'),

  /// Users are friends
  friends('friends'),

  /// There is a request from owner to target
  inputRequest('inputRequest'),

  /// There is a request from target to owner
  outputRequest('outputRequest'),

  /// There is owner profile (no target)
  owner('owner');

  const FriendshipStatus(this.wireName);

  /// Name of the status in a REST profile and in the 'join' message
  final String wireName;

  /// Returns the status named [s] by its [wireName].
  /// Throws a [StateError] when there is no such status.
  static FriendshipStatus fromString(String s) =>
      values.singleWhere((element) => element.wireName == s);
}

/// Ban status between two users
enum BanStatus {
  /// Neither user or owner bans each other
  notBanned('notBanned'),

  /// Owner was banned by user
  inputBan('inputBan'),

  /// This user banned by owner
  outputBan('outputBan'),

  /// There is owner profile
  owner('owner');

  const BanStatus(this.wireName);

  /// Name of the status in a REST profile
  final String wireName;
}

/// A data class containing base user info
class BaseProfileInfo extends Equatable {
  /// User id
  final int userId;

  /// User name
  final String login;

  /// User picture URL. May be `null`
  final String? pictureUrl;

  const BaseProfileInfo({
    required this.userId,
    required this.login,
    this.pictureUrl,
  });

  @override
  List<Object?> get props => [userId, login, pictureUrl];
}

/// A data class describing information about user
class ProfileInfo extends BaseProfileInfo {
  /// Last date when user plays online game
  final DateTime lastVisitDate;

  /// Is friend request accepted
  final Role role;

  /// User account origin
  final AuthType authType;

  /// Friendship status between authorized user and this profile
  final FriendshipStatus friendshipStatus;

  /// Ban status between authorized user and this profile
  final BanStatus banStatus;

  const ProfileInfo({
    required super.userId,
    required super.login,
    required super.pictureUrl,
    required this.role,
    required this.lastVisitDate,
    required this.banStatus,
    required this.friendshipStatus,
    required this.authType,
  });

  @override
  List<Object?> get props => [
    ...super.props,
    role,
    lastVisitDate,
    friendshipStatus,
    banStatus,
    authType,
  ];
}
