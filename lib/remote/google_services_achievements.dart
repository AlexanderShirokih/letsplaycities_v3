import 'package:flutter/services.dart';
import 'package:lets_play_cities/base/achievements/achievements.dart';
import 'package:lets_play_cities/base/achievements/achievements_service.dart';
import 'package:lets_play_cities/utils/error_logger.dart';

/// Implantation of [AchievementsService] that uses Google Game Services.
/// Platform errors are reported to the [ErrorLogger] and not rethrown.
class GoogleServicesAchievementService implements AchievementsService {
  static const MethodChannel _googleServicesChannel = MethodChannel(
    'ru.aleshi.letsplaycities/game_services',
  );

  final ErrorLogger _logger;

  GoogleServicesAchievementService(this._logger);

  @override
  Future<void> showAchievementsScreen() async {
    try {
      await _googleServicesChannel.invokeMethod('showAchievementsIntent');
    } on PlatformException catch (e, s) {
      _logger.error(e, s);
    }
  }

  @override
  Future<void> showLeaderboardScreen() async {
    try {
      await _googleServicesChannel.invokeMethod('showLeaderboardIntent');
    } on PlatformException catch (e, s) {
      _logger.error(e, s);
    }
  }

  @override
  Future<void> submitScore(int score) async {
    try {
      await _googleServicesChannel.invokeMapMethod<String, dynamic>(
        'submitScore',
        {'score': score},
      );
    } on PlatformException catch (e, s) {
      _logger.error(e, s);
    }
  }

  @override
  Future<void> unlockAchievement(
    Achievement achievement, [
    int incrementCount = 1,
  ]) async {
    try {
      await _googleServicesChannel.invokeMapMethod<String, dynamic>(
        'unlockAchievement',
        {'name': achievement.wireName, 'incrementCount': incrementCount},
      );
    } on PlatformException catch (e, s) {
      _logger.error(e, s);
    }
  }
}
