import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/base/themes/app_theme_mode.dart';

/// GetIt instance name of the app's [ValueNotifier] of [AppThemeMode]
const themeModeNotifierName = 'themeModeNotifier';

/// Saves the theme [mode] to the preferences and notifies the app
void setThemeMode(AppThemeMode mode) {
  final getIt = GetIt.instance;
  getIt.get<GamePreferences>().themeMode = mode;
  getIt
          .get<ValueNotifier<AppThemeMode>>(instanceName: themeModeNotifierName)
          .value =
      mode;
}
