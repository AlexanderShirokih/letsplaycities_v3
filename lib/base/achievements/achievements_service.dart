import 'package:lets_play_cities/base/achievements/achievements.dart';

/// Service used to collect player achievements and scores
abstract class AchievementsService {
  /// Unlocks or increments achievement
  /// [achievement] the achievement to be unlocked
  /// [incrementCount] how much achievement should be incremented. Used only
  /// for incremental achievements.
  Future<void> unlockAchievement(Achievement achievement,
      [int incrementCount = 1]);

  /// Submits score to play games server only if user logged in
  /// [score] user score to be submitted
  Future<void> submitScore(int score);

  /// Show screen with user achievements list
  Future<void> showAchievementsScreen();

  /// Shows screen with global score leaderboard
  Future<void> showLeaderboardScreen();
}

/// Stub implementation used in debugging purposes on desktop
class StubAchievementsService implements AchievementsService {
  @override
  Future<void> showAchievementsScreen() {
    return Future.value();
  }

  @override
  Future<void> showLeaderboardScreen() {
    return Future.value();
  }

  @override
  Future<void> submitScore(int score) {
    return Future.value();
  }

  @override
  Future<void> unlockAchievement(Achievement achievement,
      [int incrementCount = 1]) {
    return Future.value();
  }
}
