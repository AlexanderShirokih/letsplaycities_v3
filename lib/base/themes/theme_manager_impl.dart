import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/base/themes/theme.dart' as theme;
import 'package:lets_play_cities/base/themes/theme_manager.dart';
import 'package:rxdart/rxdart.dart';

/// Default theme manager implementation
class ThemeManagerImpl implements ThemeManager {
  static final List<theme.Theme> _themes = [
    theme.Theme(
      name: 'default',
      backgroundImage: 'assets/images/backgrounds/bg_geo.png',
      accentColor: Colors.blue[900]!,
      primaryColor: Colors.orange,
      fillColor: Color(0xFFFFD2AE),
      borderColor: Color(0xFFE9B77B),
      messageMe: Color(0xFFAEF1B0),
      messageOther: Color(0xFFAFB7F4),
    ),
    theme.Theme(
      name: 'dark',
      accentColor: Colors.deepPurple.shade700,
      primaryColor: Colors.deepPurple,
      isDark: true,
      fillColor: Colors.black45,
      borderColor: Colors.black12,
      messageMe: Colors.black45,
      messageOther: Colors.black45,
    ),
    theme.Theme(
      name: 'green',
      accentColor: Colors.green[400]!,
      primaryColor: Colors.green,
      fillColor: Color(0xFF78f979),
      borderColor: Color(0xFF8AED8D),
      messageMe: Color(0xFFBBFFC3),
      messageOther: Color(0xFFBBFFC3),
    ),
    theme.Theme(
      name: 'blue',
      accentColor: Colors.blueAccent,
      primaryColor: Colors.blue,
      fillColor: Color(0xFFA8D4F7),
      borderColor: Color(0xFF92C7F1),
      messageMe: Color(0xFFF7FFFF),
      messageOther: Color(0xFFF7FFFF),
    ),
    theme.Theme(
      name: 'autumn',
      backgroundImage: 'assets/images/backgrounds/bg_fall.png',
      accentColor: Colors.deepOrange[400]!,
      primaryColor: Colors.deepOrange,
      fillColor: Color(0xC9FFC08D),
      borderColor: Color(0xC8FF8539),
      messageMe: Color(0xFFAEF1B0),
      messageOther: Color(0xFFAFB7F4),
    ),
    theme.Theme(
      name: 'french',
      backgroundImage: 'assets/images/backgrounds/bg_eiffel.png',
      accentColor: Colors.blue[400]!,
      primaryColor: Colors.blue,
      fillColor: Color(0xFFA6F1C8),
      borderColor: Color(0xFF1feab0),
      messageMe: Color(0xFF86FFF5),
      messageOther: Color(0xFF86FFF5),
    ),
    theme.Theme(
      name: 'rus',
      backgroundImage: 'assets/images/backgrounds/bg_moscow.png',
      accentColor: Colors.indigo[800]!,
      primaryColor: Colors.indigo,
      fillColor: Color(0xE6F1F1FF),
      borderColor: Color(0xE6303EFD),
      messageMe: Colors.blue,
      messageOther: Color(0xE6EF6666),
    ),
    theme.Theme(
      name: 'ukr',
      backgroundImage: 'assets/images/backgrounds/bg_kiev.png',
      accentColor: Colors.blue[400]!,
      primaryColor: Colors.blue,
      fillColor: Color(0xE9666DEF),
      borderColor: Color(0xEB303EFD),
      messageMe: Color(0xF1EFE866),
      messageOther: Colors.blue,
    ),
    theme.Theme(
      name: 'usa',
      backgroundImage: 'assets/images/backgrounds/bg_usa.png',
      accentColor: Colors.blue,
      primaryColor: Colors.lightBlue,
      fillColor: Color(0xE6F1F1FF),
      borderColor: Color(0xDC39B0ff),
      messageMe: Color(0xDC8DD7FF),
      messageOther: Color(0xDC8DD7FF),
    ),
  ];

  final BehaviorSubject<theme.Theme> _currentTheme = BehaviorSubject();

  final GamePreferences _preferences;

  ThemeManagerImpl(this._preferences) {
    final name = _preferences.theme;
    final current = _themes.firstWhere((theme) => theme.name == name,
        orElse: () => fallback);

    // Emit current theme
    _currentTheme.add(current);
  }

  @override
  List<theme.Theme> get availableThemes => List.unmodifiable(_themes);

  @override
  theme.Theme get fallback => _themes.first;

  @override
  theme.Theme get dark => _themes.firstWhere((theme) => theme.name == 'dark');

  @override
  Stream<theme.Theme> get currentTheme => _currentTheme.stream;

  @override
  void setCurrent(theme.Theme theme) {
    _preferences.theme = theme.name;
    _currentTheme.add(theme);
  }
}
