import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/remote/model/profile_info.dart';
import 'package:lets_play_cities/remote/model/utils.dart';

/// A data class describing users friend
class FriendInfo extends BaseProfileInfo {
  /// Is friend request accepted
  final bool accepted;

  /// Is user owns this request or friendship
  final bool sender;

  const FriendInfo._({
    required super.userId,
    required super.login,
    required super.pictureUrl,
    required this.accepted,
    required this.sender,
  });

  FriendInfo.fromJson(AppConfig appConfig, Map<String, dynamic> data)
    : this._(
        userId: data['userId'],
        login: data['login'],
        accepted: data['accepted'],
        sender: data['sender'],
        pictureUrl: getPictureUrlOrNull(
          appConfig,
          data['userId'],
          data['pictureHash'],
        ),
      );

  @override
  List<Object?> get props => [...super.props, userId, login, accepted];

  /// Creates copy of this object with ability to customize some fields values
  FriendInfo copy({bool? accepted}) => FriendInfo._(
    userId: userId,
    login: login,
    pictureUrl: pictureUrl,
    accepted: accepted ?? this.accepted,
    sender: sender,
  );
}
