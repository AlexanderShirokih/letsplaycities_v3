import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/achievements/achievements.dart';
import 'package:lets_play_cities/base/achievements/achievements_service.dart';
import 'package:lets_play_cities/base/achievements/local_achievements.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingAchievements implements AchievementsService {
  final calls = <String>[];

  @override
  Future<void> unlockAchievement(
    Achievement achievement, [
    int incrementCount = 1,
  ]) async => calls.add('unlock(${achievement.wireName}, $incrementCount)');

  @override
  Future<void> submitScore(int score) async => calls.add('submitScore($score)');

  @override
  Future<void> showAchievementsScreen() async =>
      calls.add('showAchievementsScreen');

  @override
  Future<void> showLeaderboardScreen() async =>
      calls.add('showLeaderboardScreen');
}

void main() {
  late GamePreferences prefs;
  late _RecordingAchievements inner;
  late LocalAchievementsService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = SharedPreferencesGamePrefs(await SharedPreferences.getInstance());
    inner = _RecordingAchievements();
    service = LocalAchievementsService(inner, prefs);
  });

  test('incremental achievement unlocks at target', () async {
    await service.unlockAchievement(Achievement.write15Cities, 10);
    expect(service.isUnlocked(Achievement.write15Cities), isFalse);
    expect(service.progress(Achievement.write15Cities), 10);

    await service.unlockAchievement(Achievement.write15Cities, 5);
    expect(service.isUnlocked(Achievement.write15Cities), isTrue);

    await service.unlockAchievement(Achievement.write15Cities, 3);
    expect(service.isUnlocked(Achievement.write15Cities), isTrue);
    expect(service.isUnlocked(Achievement.write80Cities), isFalse);
  });

  test('one-shot achievement unlocks on first call', () async {
    expect(service.isUnlocked(Achievement.changeTheme), isFalse);

    await service.unlockAchievement(Achievement.changeTheme);

    expect(service.isUnlocked(Achievement.changeTheme), isTrue);
  });

  test('delegates to inner service', () async {
    await service.unlockAchievement(Achievement.use3Tips, 2);
    await service.submitScore(120);
    await service.showAchievementsScreen();
    await service.showLeaderboardScreen();

    expect(inner.calls, [
      'unlock(use3Tips, 2)',
      'submitScore(120)',
      'showAchievementsScreen',
      'showLeaderboardScreen',
    ]);
  });

  test('progress is kept in the preferences', () async {
    await service.unlockAchievement(Achievement.write80Cities, 30);

    final reopened = LocalAchievementsService(inner, prefs);

    expect(reopened.progress(Achievement.write80Cities), 30);
    expect(prefs.achievementsProgress, {'write80Cities': 30});
  });
}
