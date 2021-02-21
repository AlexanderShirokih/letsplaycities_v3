/// Describes information about remote server
class RemoteHost {
  /// IP address and port
  final String address;

  /// Server application string version
  final String versionName;

  /// Server application version build
  final int buildNumber;

  /// Device host name
  final String hostName;

  const RemoteHost({
    required this.address,
    required this.versionName,
    required this.buildNumber,
    required this.hostName,
  });
}
