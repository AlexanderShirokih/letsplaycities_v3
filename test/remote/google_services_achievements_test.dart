import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/achievements/achievements.dart';
import 'package:lets_play_cities/remote/google_services_achievements.dart';
import 'package:lets_play_cities/utils/error_logger.dart';

class _RecordingLogger implements ErrorLogger {
  final errors = <Object>[];

  @override
  void error(Object error, StackTrace stackTrace) => errors.add(error);

  @override
  void log(String message) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('ru.aleshi.letsplaycities/game_services');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late _RecordingLogger logger;
  late GoogleServicesAchievementService service;
  late List<MethodCall> calls;

  void handleCalls(Object? Function(MethodCall call) result) =>
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return result(call);
      });

  setUp(() {
    logger = _RecordingLogger();
    service = GoogleServicesAchievementService(logger);
    calls = [];
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
  });

  test('passes the calls to Google Game Services', () async {
    handleCalls((_) => null);

    await service.showAchievementsScreen();
    await service.showLeaderboardScreen();
    await service.submitScore(1200);
    await service.unlockAchievement(Achievement.use3Tips, 2);

    expect(calls.map((call) => call.method), [
      'showAchievementsIntent',
      'showLeaderboardIntent',
      'submitScore',
      'unlockAchievement',
    ]);
    expect(calls[2].arguments, {'score': 1200});
    expect(calls[3].arguments, {'name': 'use3Tips', 'incrementCount': 2});
    expect(logger.errors, isEmpty);
  });

  // The Android side looks these names up among its own Achievement
  // constants, ignoring case; a name it does not know is an error there.
  test('names every achievement as the native side expects', () async {
    const names = {
      Achievement.write15Cities: 'write15Cities',
      Achievement.use3Tips: 'use3Tips',
      Achievement.add1Friend: 'add1Friend',
      Achievement.playInHardMode: 'playInHardMode',
      Achievement.reachScore1000Pts: 'reachScore1000Pts',
      Achievement.write80Cities: 'write80Cities',
      Achievement.loginViaSocial: 'loginViaSocial',
      Achievement.changeTheme: 'changeTheme',
      Achievement.write50CitiesInGame: 'write50CitiesInGame',
      Achievement.playOnline3Times: 'playOnline3Times',
      Achievement.use30Tips: 'use30Tips',
      Achievement.reachScore5000Pts: 'reachScore5000Pts',
      Achievement.write500Cities: 'write500Cities',
      Achievement.write100CitiesInGame: 'write100CitiesInGame',
      Achievement.reachScore25000Pts: 'reachScore25000Pts',
    };
    handleCalls((_) => null);

    for (final achievement in Achievement.values) {
      await service.unlockAchievement(achievement);
    }

    expect(
      calls.map((call) => (call.arguments as Map)['name']),
      Achievement.values.map((achievement) => names[achievement]),
    );
  });

  test('logs a platform error of every call instead of throwing', () async {
    handleCalls(
      (call) => throw PlatformException(code: 'SIGN_IN', message: call.method),
    );

    await service.showAchievementsScreen();
    await service.showLeaderboardScreen();
    await service.submitScore(1200);
    await service.unlockAchievement(Achievement.use3Tips);

    expect(logger.errors.map((e) => (e as PlatformException).message), [
      'showAchievementsIntent',
      'showLeaderboardIntent',
      'submitScore',
      'unlockAchievement',
    ]);
  });
}
