import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/app_config.dart';

/// Creates avatar picture url from template.
/// Returns `null` if [pictureHash] is `null` or an empty string
String? getPictureUrlOrNull(int userId, String? pictureHash) => pictureHash ==
            null ||
        pictureHash.isEmpty
    ? null
    : '${GetIt.instance.get<AppConfig>().remotePublicApiURL}/user/$userId/picture?hash=$pictureHash';
