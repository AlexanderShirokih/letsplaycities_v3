import 'package:lets_play_cities/app_config.dart';

/// Creates avatar picture url from template.
/// Returns `null` if [pictureHash] is `null` or an empty string
String? getPictureUrlOrNull(
        AppConfig appConfig, int userId, String? pictureHash) =>
    pictureHash == null || pictureHash.isEmpty
        ? null
        : '${appConfig.remotePublicApiURL}/user/$userId/picture?hash=$pictureHash';

/// Creates avatar picture url from template.
/// Don't takes into account picture hash code
String? getPictureUrlOrNullNoHash(AppConfig appConfig, String userId) =>
    '${appConfig.remotePublicApiURL}/user/$userId/picture';
