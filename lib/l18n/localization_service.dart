import 'package:lets_play_cities/screens/game/first_time_onboarding_screen.dart';
import 'package:lets_play_cities/screens/game_results/game_results_screen.dart';
import 'package:lets_play_cities/screens/main/citieslist/cities_list_about_screen.dart';

import 'localizations_keys.dart';

/// Represents interface for loading localized strings
abstract class LocalizationService {
  Map<ErrorCode, String> get exclusionDescriptions;

  String get yes;

  String get no;

  String get cancel;

  String get back;

  String get apply;

  /// [GameScreen] localizations
  Map<String, dynamic> get game;

  /// [SettingsScreen] localizations
  Map<String, dynamic> get settings;

  /// [StatisticsScreen] localizations
  Map<String, dynamic> get stats;

  /// [CitiesListScreen] localizations
  Map<String, dynamic> get citiesList;

  /// [CitiesListAboutScreen] localizations
  Map<String, dynamic> get citiesListAbout;

  /// [GameResultsScreen] localizations
  Map<String, dynamic> get gameResults;

  /// [FirstTimeOnBoardingScreen] localizations
  Map<String, dynamic> get firstTimeOnBoarding;

  /// [OnlineGameMasterScreen] localizations
  Map<String, dynamic> get online => null;
}
