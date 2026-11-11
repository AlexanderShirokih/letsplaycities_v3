import 'package:flutter/material.dart';

/// Design tokens, available through [Theme.extension]
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color bg;
  final Color surface;
  final Color ink;
  final Color inkSoft;
  final Color orange;
  final Color violet;
  final Color yellow;
  final Color error;

  /// Highlighted last letter of a city
  final Color letter;

  /// Card shadow, borders, timer track
  final Color edge;
  final Color mint;
  final Color sky;

  /// Hard shadow of buttons
  final Color shadow;

  const AppColors({
    required this.bg,
    required this.surface,
    required this.ink,
    required this.inkSoft,
    required this.orange,
    required this.violet,
    required this.yellow,
    required this.error,
    required this.letter,
    required this.edge,
    required this.mint,
    required this.sky,
    required this.shadow,
  });

  static const light = AppColors(
    bg: Color(0xFFF1EEFF),
    surface: Color(0xFFFFFFFF),
    ink: Color(0xFF1B1340),
    inkSoft: Color(0xFF5B5480),
    orange: Color(0xFFFF7A1A),
    violet: Color(0xFF5B3DF5),
    yellow: Color(0xFFFFC93C),
    error: Color(0xFFC42B1C),
    letter: Color(0xFFB84E00),
    edge: Color(0xFFD6CEFA),
    mint: Color(0xFF52D6A4),
    sky: Color(0xFF8EC9FF),
    shadow: Color(0xFF1B1340),
  );

  static const dark = AppColors(
    bg: Color(0xFF151034),
    surface: Color(0xFF221A4D),
    ink: Color(0xFFF1EEFF),
    inkSoft: Color(0xFFB9AEF0),
    orange: Color(0xFFFF7A1A),
    violet: Color(0xFF5B3DF5),
    yellow: Color(0xFFFFC93C),
    error: Color(0xFFC42B1C),
    // The light letter color is too dim on a dark surface
    letter: Color(0xFFFF7A1A),
    edge: Color(0xFF3A3170),
    mint: Color(0xFF52D6A4),
    sky: Color(0xFF8EC9FF),
    shadow: Color(0xFF0B0820),
  );

  /// Tokens of the theme in effect for [context]
  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>() ?? light;

  @override
  AppColors copyWith({
    Color? bg,
    Color? surface,
    Color? ink,
    Color? inkSoft,
    Color? orange,
    Color? violet,
    Color? yellow,
    Color? error,
    Color? letter,
    Color? edge,
    Color? mint,
    Color? sky,
    Color? shadow,
  }) => AppColors(
    bg: bg ?? this.bg,
    surface: surface ?? this.surface,
    ink: ink ?? this.ink,
    inkSoft: inkSoft ?? this.inkSoft,
    orange: orange ?? this.orange,
    violet: violet ?? this.violet,
    yellow: yellow ?? this.yellow,
    error: error ?? this.error,
    letter: letter ?? this.letter,
    edge: edge ?? this.edge,
    mint: mint ?? this.mint,
    sky: sky ?? this.sky,
    shadow: shadow ?? this.shadow,
  );

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;

    return AppColors(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkSoft: Color.lerp(inkSoft, other.inkSoft, t)!,
      orange: Color.lerp(orange, other.orange, t)!,
      violet: Color.lerp(violet, other.violet, t)!,
      yellow: Color.lerp(yellow, other.yellow, t)!,
      error: Color.lerp(error, other.error, t)!,
      letter: Color.lerp(letter, other.letter, t)!,
      edge: Color.lerp(edge, other.edge, t)!,
      mint: Color.lerp(mint, other.mint, t)!,
      sky: Color.lerp(sky, other.sky, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}
