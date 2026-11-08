import 'dart:math';

import 'package:lets_play_cities/base/achievements/achievements.dart';
import 'package:lets_play_cities/base/achievements/achievements_service.dart';
import 'package:lets_play_cities/base/preferences.dart';

/// Progress at which an incremental achievement is unlocked. Every other
/// achievement is unlocked by its first call.
const achievementTargets = <Achievement, int>{
  Achievement.write15Cities: 15,
  Achievement.write80Cities: 80,
  Achievement.write500Cities: 500,
  Achievement.reachScore1000Pts: 1000,
  Achievement.reachScore5000Pts: 5000,
  Achievement.reachScore25000Pts: 25000,
  Achievement.use3Tips: 3,
  Achievement.use30Tips: 30,
  Achievement.playOnline3Times: 3,
};

/// Keeps achievements on the device alongside [_inner], which reports them
/// to the game services.
class LocalAchievementsService implements AchievementsService {
  final AchievementsService _inner;
  final GamePreferences _prefs;

  LocalAchievementsService(this._inner, this._prefs);

  /// Progress of [achievement], at most its target
  int progress(Achievement achievement) =>
      _prefs.achievementsProgress[achievement.wireName] ?? 0;

  /// `true` once the progress of [achievement] reaches its target
  bool isUnlocked(Achievement achievement) =>
      progress(achievement) >= _target(achievement);

  /// Adds [incrementCount] to the local progress, then reports it to the
  /// game services.
  @override
  Future<void> unlockAchievement(
    Achievement achievement, [
    int incrementCount = 1,
  ]) {
    final all = Map.of(_prefs.achievementsProgress);
    final current = all[achievement.wireName] ?? 0;
    all[achievement.wireName] = min(
      current + incrementCount,
      _target(achievement),
    );
    _prefs.achievementsProgress = all;

    return _inner.unlockAchievement(achievement, incrementCount);
  }

  @override
  Future<void> submitScore(int score) => _inner.submitScore(score);

  @override
  Future<void> showAchievementsScreen() => _inner.showAchievementsScreen();

  @override
  Future<void> showLeaderboardScreen() => _inner.showLeaderboardScreen();

  static int _target(Achievement achievement) =>
      achievementTargets[achievement] ?? 1;
}
