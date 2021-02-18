import 'package:lets_play_cities/base/data/app_version.dart';

/// Describes information about remote server
class RemoteHost {
  /// IP address and port
  final String address;

  /// Server application version build and version code
  final VersionInfo version;

  /// Device host name
  final String hostName;

  const RemoteHost({
    required this.address,
    required this.version,
    required this.hostName,
  });
}
