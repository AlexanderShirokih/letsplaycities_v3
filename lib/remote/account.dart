import 'package:equatable/equatable.dart';
import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/remote/model/lps_user.dart';

export 'package:lets_play_cities/base/data/account_info.dart';

/// Account of another user: the opponent of a network game
class AdvancedAccountInfo extends ClientAccountInfo with Equatable {
  /// Id of the user on the game server
  final int userId;

  @override
  final String name;

  /// Picture of the user, `null` if there is none
  final String? pictureUrl;

  @override
  final bool canReceiveMessages;

  AdvancedAccountInfo({
    required this.userId,
    required this.name,
    this.pictureUrl,
    required this.canReceiveMessages,
  });

  @override
  PictureSource get picture => NetworkPictureSource(pictureUrl);

  @override
  List<Object> get props => [userId, name, picture];
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
}
