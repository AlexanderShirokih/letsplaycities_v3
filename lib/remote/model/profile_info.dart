import 'package:equatable/equatable.dart';
import 'package:lets_play_cities/remote/model/utils.dart';
import 'package:meta/meta.dart';

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

/// A data class describing information about user
class ProfileInfo extends Equatable {
  /// User id
  final int userId;

  /// User name
  final String login;

  /// Last date when user plays online game
  final DateTime lastVisitDate;

  /// Is friend request accepted
  final Role role;

  /// Users profile picture url
  final String pictureUrl;

  const ProfileInfo._({
    @required this.userId,
    @required this.login,
    @required this.pictureUrl,
    @required this.role,
    @required this.lastVisitDate,
  })  : assert(login != null),
        assert(userId != null),
        assert(role != null),
        assert(lastVisitDate != null);

  ProfileInfo.fromJson(Map<String, dynamic> data)
      : this._(
          userId: data['userId'],
          login: data['login'],
          role: RoleExt.fromString(data['role']),
          lastVisitDate:
              DateTime.fromMillisecondsSinceEpoch(data['lastVisitDate']),
          pictureUrl: getPictureUrlOrNull(data['userId'], data['pictureHash']),
        );

  @override
  List<Object> get props => [userId, login, role, lastVisitDate, pictureUrl];
}
