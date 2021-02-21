/// Game modes
enum GameMode { playerVsAndroid, playerVsPlayer, multiplayer, network }

extension GameModeParams on GameMode {
  /// Returns `true` if this game mode is local (is not remote)
  bool get isLocal =>
      this == GameMode.playerVsAndroid || this == GameMode.playerVsPlayer;
}
