import 'package:flutter/services.dart';
import 'package:lets_play_cities/base/data/app_version.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:package_info/package_info.dart';

/// Retrieves client application version
Future<VersionInfo> getAppVersion() async {
  try {
    var packageInfo = await PackageInfo.fromPlatform();

    var version = packageInfo.version;
    var buildNumber = packageInfo.buildNumber;

    return VersionInfo(version, int.parse(buildNumber));
  } on MissingPluginException {
    return VersionInfo('3.0.0', 3000);
  }
}
