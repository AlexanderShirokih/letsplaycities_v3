import 'package:lets_play_cities/app_config.dart';

/// Creates avatar picture url from template.
/// Returns `null` if [pictureHash] is `null` or an empty string
String getPictureUrlOrNull(int userId, String pictureHash) => pictureHash ==
            null ||
        pictureHash.isEmpty
    ? null
    : '${AppConfig.remotePublicApiURL}/user/$userId/picture?hash=$pictureHash';
