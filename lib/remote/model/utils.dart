import 'package:lets_play_cities/app_config.dart';

/// Creates the avatar URL `{base}/v1/avatars/{id}?v={hash}`. Returns `null`
/// if [pictureHash] is `null` or an empty string
String? getPictureUrlOrNull(
  AppConfig appConfig,
  int userId,
  String? pictureHash,
) => pictureHash == null || pictureHash.isEmpty
    ? null
    : '${appConfig.restBaseUrl}/avatars/$userId?v=${Uri.encodeQueryComponent(pictureHash)}';

/// Creates the avatar URL without the version of the picture
String? getPictureUrlOrNullNoHash(AppConfig appConfig, String userId) =>
    '${appConfig.restBaseUrl}/avatars/$userId';
