import 'package:equatable/equatable.dart';
import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/remote/auth.dart';

export 'package:lets_play_cities/base/data/account_info.dart';

/// [ClientAccountInfo] constructed from [ProfileInfo]
class AdvancedAccountInfo extends ClientAccountInfo with Equatable {
  final ProfileInfo profileInfo;

  @override
  final bool canReceiveMessages;

  AdvancedAccountInfo(this.profileInfo, this.canReceiveMessages);

  @override
  String get name => profileInfo.login;

  @override
  PictureSource get picture => NetworkPictureSource(profileInfo.pictureUrl);

  @override
  List<Object> get props => [name, picture];
}

/// Contains remote account info of the user
class RemoteAccount extends ClientAccountInfo with Equatable {
  /// Unique user ID.
  /// Used to uniquely identify user on the game server.
  final int userId;

  /// Users role on server
  final Role role;

  /// Account origin
  final AuthType authType;

  RemoteAccount({
    required this.userId,
    required this.name,
    required this.canReceiveMessages,
    required this.role,
    required this.authType,
    required String? pictureUri,
  }) : picture = NetworkPictureSource(pictureUri);

  @override
  final String name;

  @override
  final PictureSource picture;

  @override
  final bool canReceiveMessages;

  @override
  List<Object> get props => [userId, name, picture];

  /// Returns [BaseProfileInfo] for this account
  BaseProfileInfo get baseProfileInfo => BaseProfileInfo(
    userId: userId,
    login: name,
    pictureUrl: (picture as NetworkPictureSource).pictureURL,
  );
}
