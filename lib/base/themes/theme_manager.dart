import 'theme.dart';

/// Controls theme switching
abstract class ThemeManager {
  /// Currently active theme
  Stream<Theme> get currentTheme;

  /// Default app theme
  Theme get fallback;

  /// Default dark theme
  Theme get dark;

  /// All application themes
  List<Theme> get availableThemes;

  /// Sets the current theme
  void setCurrent(Theme theme);
}
