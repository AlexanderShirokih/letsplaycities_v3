import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/remote/auth.dart';

import 'utils.dart';

/// A data class describing banned user (blacklist entity)
class BlackListItemInfo extends BaseProfileInfo {
  /// Banned user picture URL

  const BlackListItemInfo._({
    required int userId,
    required String login,
    required String? pictureUrl,
  }) : super(
          userId: userId,
          login: login,
          pictureUrl: pictureUrl,
        );

  BlackListItemInfo.fromJson(Map<String, dynamic> data)
      : this._(
          userId: data['userId'],
          login: data['login'],
          pictureUrl: getPictureUrlOrNull(
              GetIt.instance<AppConfig>(), data['userId'], data['pictureHash']),
        );
}
