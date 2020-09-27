import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import 'package:lets_play_cities/remote/model/utils.dart';

/// A data class describing users friend
class FriendInfo extends Equatable {
  /// Friend user name
  final String login;

  /// Friend user picture URL
  final String pictureUrl;

  /// Friend user id
  final int userId;

  /// Is friend request accepted
  final bool accepted;

  /// Is user owns this request or friendship
  final bool isSender;

  const FriendInfo._({
    @required this.userId,
    @required this.login,
    @required this.pictureUrl,
    @required this.accepted,
    @required this.isSender,
  })  : assert(login != null),
        assert(userId != null),
        assert(accepted != null),
        assert(isSender != null);

  FriendInfo.fromJson(Map<String, dynamic> data)
      : this._(
          userId: data['userId'],
          login: data['login'],
          accepted: data['accepted'],
          isSender: data['isSender'],
          pictureUrl: getPictureUrlOrNull(data['userId'], data['pictureHash']),
        );

  @override
  List<Object> get props => [userId, login, accepted, pictureUrl];

  /// Creates copy of this object with ability to customize some fields values
  FriendInfo copy({bool accepted}) => FriendInfo._(
        userId: userId,
        login: login,
        pictureUrl: pictureUrl,
        accepted: accepted ?? this.accepted,
        isSender: isSender,
      );
}
