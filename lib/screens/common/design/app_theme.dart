import 'package:flutter/material.dart';
import 'package:lets_play_cities/screens/common/design/app_colors.dart';
import 'package:lets_play_cities/screens/common/design/app_text.dart';

/// Builds the app theme for [brightness]
ThemeData buildAppTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final c = isDark ? AppColors.dark : AppColors.light;
  final base = ThemeData(brightness: brightness).textTheme;
  final body = AppText.body.copyWith(color: c.ink);
  final bodyRegular = AppText.bodyRegular.copyWith(color: c.ink);

  return ThemeData(
    useMaterial3: false,
    brightness: brightness,
    fontFamily: AppText.rubik,
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
      onSecondary: AppColors.light.ink,
      error: c.error,
      onError: Colors.white,
      surface: c.surface,
      onSurface: c.ink,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: c.bg,
      foregroundColor: c.ink,
      elevation: 0,
      titleTextStyle: AppText.title.copyWith(color: c.ink),
    ),
    textTheme: base
        .copyWith(
          displayLarge: AppText.display,
          displayMedium: AppText.display,
          displaySmall: AppText.display,
          headlineLarge: AppText.title,
          headlineMedium: AppText.title,
          headlineSmall: AppText.title,
          titleLarge: AppText.title,
          titleMedium: AppText.section,
          titleSmall: AppText.section,
          bodyLarge: body,
          bodyMedium: bodyRegular,
          bodySmall: AppText.caption,
          labelLarge: body,
          labelMedium: AppText.small,
          labelSmall: AppText.small,
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
