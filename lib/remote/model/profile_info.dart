import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:lets_play_cities/remote/model/utils.dart';

import 'auth_type.dart';

/// Describes user roles
enum Role {
  /// Used when user is banned
  banned,

  /// Default user state
  regular,

  /// Used when user has admin privileges
  admin
}

extension RoleExt on Role {
  /// Converts string role representation to [Role] value.
  static Role fromString(String role) {
    switch (role) {
      case 'REGULAR_USER':
        return Role.regular;
      case 'ADMIN':
        return Role.admin;
      case 'BANNED_USER':
        return Role.banned;
    }
    throw ('Bad state! role=$role');
  }
}

/// Friendship status between two users
enum FriendshipStatus {
  /// Users aren't friends
  notFriends,

  /// Users are friends
  friends,

  /// There is a request from owner to target
  inputRequest,

  /// There is a request from target to owner
  outputRequest,

  /// There is owner profile (no target)
  owner,
}

enum BanStatus {
  /// Neither user or owner bans each other
  notBanned,

  /// Owner was banned by user
  inputBan,

  /// This user banned by owner
  outputBan,

  /// There is owner profile
  owner
}

extension BanStatusExt on BanStatus {
  /// Converts string representation of this enum to enum constant
  static BanStatus fromString(String s) =>
      BanStatus.values.singleWhere((element) => describeEnum(element) == s);

  /// Converts enum value to string representation
  String asString() => describeEnum(this);
}

extension FriendshipStatusExt on FriendshipStatus {
  /// Converts string representation of this enum to enum constant
  static FriendshipStatus fromString(String s) => FriendshipStatus.values
      .singleWhere((element) => describeEnum(element) == s);

  /// Converts enum value to string representation
  String asString() => describeEnum(this);
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
    required int userId,
    required String login,
    required String? pictureUrl,
    required this.role,
    required this.lastVisitDate,
    required this.banStatus,
    required this.friendshipStatus,
    required this.authType,
  }) : super(
          userId: userId,
          login: login,
          pictureUrl: pictureUrl,
        );

  ProfileInfo.fromJson(Map<String, dynamic> data)
      : this(
          login: data['login'],
          userId: data['userId'],
          friendshipStatus:
              FriendshipStatusExt.fromString(data['friendshipStatus']),
          banStatus: BanStatusExt.fromString(data['banStatus']),
          role: RoleExt.fromString(data['role']),
          authType: AuthTypeExtension.fromString(data['authType']),
          lastVisitDate:
              DateTime.fromMillisecondsSinceEpoch(data['lastVisitDate']),
          pictureUrl: getPictureUrlOrNull(data['userId'], data['pictureHash']),
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
