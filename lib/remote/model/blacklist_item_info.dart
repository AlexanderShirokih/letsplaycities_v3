import 'package:lets_play_cities/remote/auth.dart';
import 'package:meta/meta.dart';

import 'utils.dart';

/// A data class describing banned user (blacklist entity)
class BlackListItemInfo extends BaseProfileInfo {
  /// Banned user picture URL

  const BlackListItemInfo._({
    @required int userId,
    @required String login,
    @required String pictureUrl,
  }) : super(
          userId: userId,
          login: login,
          pictureUrl: pictureUrl,
        );

  BlackListItemInfo.fromJson(Map<String, dynamic> data)
      : this._(
          userId: data['userId'],
          login: data['login'],
          pictureUrl: getPictureUrlOrNull(data['userId'], data['pictureHash']),
        );
}
