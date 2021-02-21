/// Game modes
enum GameMode { PlayerVsAndroid, PlayerVsPlayer, Network }

extension GameModeParams on GameMode {
  /// Returns `true` if this game mode is local (is not remote)
  bool get isLocal => this != GameMode.Network;
}
