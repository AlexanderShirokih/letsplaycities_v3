/// Names of the users in a game on one device, which has no accounts to take
/// them from.
class DefaultPlayerNames {
  /// The player in a game against the android.
  final String player;

  /// The android in a game against the player.
  final String android;

  /// The player who moves first in a game of two players.
  final String firstPlayer;

  /// The player who moves second in a game of two players.
  final String secondPlayer;

  const DefaultPlayerNames({
    required this.player,
    required this.android,
    required this.firstPlayer,
    required this.secondPlayer,
  });
}
