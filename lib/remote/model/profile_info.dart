import 'package:equatable/equatable.dart';
import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/remote/model/utils.dart';

import 'auth_type.dart';

/// Describes user roles
enum Role {
  /// Used when user is banned
  banned('BANNED_USER', 'banned'),

  /// Default user state
  regular('REGULAR_USER', 'ready'),

  /// Used when user has admin privileges
  admin('ADMIN', 'admin');

  const Role(this.wireName, this.signUpState);

  /// Name of the role in a profile of the REST API ('role')
  final String wireName;

  /// Name of the role in the sign-up response ('state')
  final String signUpState;

  /// Converts string role representation to [Role] value.
  /// Throws a [String] when there is no such role.
  static Role fromString(String role) {
    for (final value in values) {
      if (value.wireName == role) {
        return value;
      }
    }
    throw ('Bad state! role=$role');
  }

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

  /// Returns the status named [s] by its [wireName].
  /// Throws a [StateError] when there is no such status.
  static BanStatus fromString(String s) =>
      values.singleWhere((element) => element.wireName == s);
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

  ProfileInfo.fromJson(AppConfig appConfig, Map<String, dynamic> data)
    : this(
        login: data['login'],
        userId: data['userId'],
        friendshipStatus: FriendshipStatus.fromString(data['friendshipStatus']),
        banStatus: BanStatus.fromString(data['banStatus']),
        role: Role.fromString(data['role']),
        authType: AuthType.fromString(data['authType']),
        lastVisitDate: DateTime.fromMillisecondsSinceEpoch(
          data['lastVisitDate'],
        ),
        pictureUrl: getPictureUrlOrNull(
          appConfig,
          data['userId'],
          data['pictureHash'],
        ),
      );

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
