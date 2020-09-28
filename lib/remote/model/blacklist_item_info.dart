
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import 'utils.dart';

/// A data class describing banned user (blacklist entity)
class BlackListItemInfo extends Equatable {
  /// Banned user name
  final String login;

  /// Banned user picture URL
  final String pictureUrl;

  /// Banned user id
  final int userId;

  const BlackListItemInfo._(
      {@required this.userId, @required this.login, @required this.pictureUrl})
      : assert(login != null),
        assert(userId != null);

  BlackListItemInfo.fromJson(Map<String, dynamic> data)
      : this._(
          userId: data['userId'],
          login: data['login'],
          pictureUrl: getPictureUrlOrNull(data['userId'], data['pictureHash']),
        );

  @override
  List<Object> get props => [userId, login, pictureUrl];

  /// Creates a copy of this object
  BlackListItemInfo copy() => BlackListItemInfo._(
        userId: userId,
        login: login,
        pictureUrl: pictureUrl,
      );
}
