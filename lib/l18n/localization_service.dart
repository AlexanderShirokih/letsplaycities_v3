import 'package:lets_play_cities/screens/settings/stats/stats_screen.dart';

import 'localizations_keys.dart';

/// Represents interface for loading localized strings
abstract class LocalizationService {
  Map<ErrorCode, String> get exclusionDescriptions;

  String get yes;

  String get no;

  String get cancel;

  String get back;

  /// [GameScreen] localizations
  Map<String, dynamic> get game;

  /// [SettingsScreen] localizations
  Map<String, dynamic> get settings;

  /// [StatisticsScreen] localizations
  Map<String, dynamic> get  stats;
}
