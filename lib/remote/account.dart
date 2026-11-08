import 'package:equatable/equatable.dart';
import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/model/lps_user.dart';

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

/// The signed-in account of the user
class RemoteAccount extends ClientAccountInfo with Equatable {
  final LpsUser user;

  /// Avatar of [user], `null` if there is none
  final String? avatarUrl;

  @override
  final bool canReceiveMessages;

  RemoteAccount(this.user, {this.avatarUrl, this.canReceiveMessages = false});

  /// Unique user ID on the game server
  int get userId => user.id;

  @override
  String get name => user.name;

  @override
  PictureSource get picture => NetworkPictureSource(avatarUrl);

  @override
  List<Object?> get props => [user, avatarUrl, canReceiveMessages];

  /// Returns [BaseProfileInfo] for this account
  BaseProfileInfo get baseProfileInfo =>
      BaseProfileInfo(userId: userId, login: name, pictureUrl: avatarUrl);
}
