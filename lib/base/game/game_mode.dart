/// Game modes
enum GameMode { PlayerVsAndroid, PlayerVsPlayer, Multiplayer, Network }

extension GameModeParams on GameMode {
  /// Returns `true` if this game mode is local (is not remote)
  bool isLocal() =>
      this == GameMode.PlayerVsAndroid || this == GameMode.PlayerVsPlayer;
}
