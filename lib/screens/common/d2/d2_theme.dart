import 'package:flutter/material.dart';
import 'package:lets_play_cities/screens/common/d2/d2_colors.dart';
import 'package:lets_play_cities/screens/common/d2/d2_text.dart';

/// Builds the app theme for [brightness]
ThemeData buildD2Theme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final c = isDark ? D2Colors.dark : D2Colors.light;
  final base = ThemeData(brightness: brightness).textTheme;
  final body = D2Text.body.copyWith(color: c.ink);
  final bodyRegular = D2Text.bodyRegular.copyWith(color: c.ink);

  return ThemeData(
    useMaterial3: false,
    brightness: brightness,
    fontFamily: D2Text.rubik,
    primarySwatch: _violetSwatch,
    primaryColor: c.violet,
    scaffoldBackgroundColor: c.bg,
    canvasColor: c.bg,
    cardColor: c.surface,
    dividerColor: c.edge,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    extensions: [c],
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: c.violet,
      onPrimary: Colors.white,
      secondary: c.orange,
      onSecondary: D2Colors.light.ink,
      error: c.error,
      onError: Colors.white,
      surface: c.surface,
      onSurface: c.ink,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: c.bg,
      foregroundColor: c.ink,
      elevation: 0,
      titleTextStyle: D2Text.title.copyWith(color: c.ink),
    ),
    textTheme: base
        .copyWith(
          displayLarge: D2Text.display,
          displayMedium: D2Text.display,
          displaySmall: D2Text.display,
          headlineLarge: D2Text.title,
          headlineMedium: D2Text.title,
          headlineSmall: D2Text.title,
          titleLarge: D2Text.title,
          titleMedium: D2Text.section,
          titleSmall: D2Text.section,
          bodyLarge: body,
          bodyMedium: bodyRegular,
          bodySmall: D2Text.caption,
          labelLarge: body,
          labelMedium: D2Text.small,
          labelSmall: D2Text.small,
        )
        .apply(displayColor: c.ink, bodyColor: c.ink),
  );
}

const _violetSwatch = MaterialColor(0xFF5B3DF5, {
  50: Color(0xFFEEEAFE),
  100: Color(0xFFD6CEFC),
  200: Color(0xFFB9ACFA),
  300: Color(0xFF9B89F8),
  400: Color(0xFF7E66F7),
  500: Color(0xFF5B3DF5),
  600: Color(0xFF5237DD),
  700: Color(0xFF452DB8),
  800: Color(0xFF392494),
  900: Color(0xFF281970),
});
