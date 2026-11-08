import 'package:flutter/material.dart';

/// Theme mode chosen by the user
enum AppThemeMode {
  light,
  dark,
  system;

  /// Material counterpart of this mode
  ThemeMode get asThemeMode => switch (this) {
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
    AppThemeMode.system => ThemeMode.system,
  };
}
