import 'package:lets_play_cities/base/auth.dart';

import 'app_version.dart';

/// Describes player data and its account data
class PlayerData {
  final VersionInfo versionInfo;
  final ClientAccountInfo accountInfo;
  final bool canReceiveMessages;
  final bool isFriend;

  const PlayerData({
    this.versionInfo,
    this.accountInfo,
    this.canReceiveMessages = false,
    this.isFriend = false,
  });
}
