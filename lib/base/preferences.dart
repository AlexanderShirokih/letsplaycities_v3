/// Represents application preferences
class GamePreferences {
  /// Words difficulty level.
  /// Where: 0- easy, 1-medium, 2-hard.
  int get wordsDifficulty => 0;

  /// `true` when words spelling correction is enabled.
  bool isCorrectionEnabled() => false;

  /// Time limit per users move in local game modes.
  /// `0` means timer is disabled.
  int get timeLimit => 0;
}
