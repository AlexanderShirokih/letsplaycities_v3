/// Game modes
enum GameMode { playerVsAndroid, playerVsPlayer, multiplayer, network }

extension GameModeParams on GameMode {
  /// Returns `true` if this game mode is local (is not remote)
  bool get isLocal =>
      this == GameMode.playerVsAndroid || this == GameMode.playerVsPlayer;

  /// `true` when a server judges the moves, runs the clock and ends the game:
  /// the network game and the LAN game
  bool get isServerAuthoritative =>
      this == GameMode.network || this == GameMode.multiplayer;
}
