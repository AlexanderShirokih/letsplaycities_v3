import 'package:lets_play_cities/base/data/app_version.dart';
import 'package:package_info/package_info.dart';

/// Retrieves client application version
Future<VersionInfo> getAppVersion() async {
  PackageInfo packageInfo = await PackageInfo.fromPlatform();

  String version = packageInfo.version;
  String buildNumber = packageInfo.buildNumber;

  return VersionInfo(version, int.parse(buildNumber) ?? 0);
}
