import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/remote/auth.dart';

import 'utils.dart';

/// A data class describing banned user (blacklist entity)
class BlackListItemInfo extends BaseProfileInfo {
  /// Banned user picture URL

  const BlackListItemInfo._({
    required super.userId,
    required super.login,
    required super.pictureUrl,
  });

  BlackListItemInfo.fromJson(AppConfig appConfig, Map<String, dynamic> data)
    : this._(
        userId: data['userId'],
        login: data['login'],
        pictureUrl: getPictureUrlOrNull(
          appConfig,
          data['userId'],
          data['pictureHash'],
        ),
      );
}
