import 'package:lets_play_cities/screens/game/first_time_onboarding_screen.dart';
import 'package:lets_play_cities/screens/game_results/game_results_screen.dart';
import 'package:lets_play_cities/screens/main/cites/requests/city_edit_actions_screen.dart';
import 'package:lets_play_cities/screens/main/cites/list/cities_list_about_screen.dart';
import 'package:lets_play_cities/screens/settings/theme_manager_screen.dart';

import 'localizations_keys.dart';

/// Represents interface for loading localized strings
abstract class LocalizationService {
  Map<ErrorCode, String> get exclusionDescriptions;

  String get yes;

  String get no;

  String get cancel;

  String get edit;

  String get back;

  String get apply;

  String get accept;

  String get decline;

  String get delete;

  /// [GameScreen] localizations
  Map<String, dynamic> get game;

  /// [SettingsScreen] localizations
  Map<String, dynamic> get settings;

  /// [StatisticsScreen] localizations
  Map<String, dynamic> get stats;

  /// [CitiesListScreen] localizations
  Map<String, dynamic> get citiesList;

  /// [CitiesListAboutScreen] localizations
  /// TODO: Remove
  Map<String, dynamic> get citiesListAbout;

  /// [CityEditActionsScreen] localizations
  Map<String, dynamic> get citiesRequest;

  /// [GameResultsScreen] localizations
  Map<String, dynamic> get gameResults;

  /// [FirstTimeOnBoardingScreen] localizations
  Map<String, dynamic> get firstTimeOnBoarding;

  /// [OnlineGameMasterScreen] localizations
  Map<String, dynamic> get online;

  /// Miscellaneous localizations
  Map<String, dynamic> get misc;

  /// [ThemeManagerScreen] localizations
  Map<String, dynamic> get themes;
}
