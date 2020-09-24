class VersionInfo {
  final String version;
  final int buildNumber;

  const VersionInfo(this.version, this.buildNumber);

  const VersionInfo.stub() : this('', 0);
}
