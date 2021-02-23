import 'package:flutter/services.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:package_info/package_info.dart';

/// Provides application version
class VersionInfoService {
  /// String version representation
  final String name;

  /// Integer build code
  final int build;

  VersionInfoService._(this.name, this.build);

  static VersionInfoService? _instance;

  static VersionInfoService get instance {
    if (_instance == null) {
      throw 'VersionInfoService is not initialized!';
    }

    return _instance!;
  }

  static Future<VersionInfoService> initInstance() async {
    _instance = await _fetchAppVersion();
    return _instance!;
  }

  static Future<VersionInfoService> _fetchAppVersion() async {
    try {
      var packageInfo = await PackageInfo.fromPlatform();

      var version = packageInfo.version;
      var buildNumber = packageInfo.buildNumber;

      return VersionInfoService._(version, int.parse(buildNumber));
    } on MissingPluginException {
      return VersionInfoService._('3.0.1-desktop', 3010);
    }
  }
}
