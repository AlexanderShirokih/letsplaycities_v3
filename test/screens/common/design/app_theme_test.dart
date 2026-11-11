import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/screens/common/design/app_colors.dart';
import 'package:lets_play_cities/screens/common/design/app_text.dart';
import 'package:lets_play_cities/screens/common/design/app_theme.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;

  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  test('light tokens match spec', () {
    expect(AppColors.light.bg, const Color(0xFFF1EEFF));
    expect(AppColors.light.ink, const Color(0xFF1B1340));
    expect(AppColors.light.orange, const Color(0xFFFF7A1A));
    expect(AppColors.light.violet, const Color(0xFF5B3DF5));
    expect(AppColors.light.letter, const Color(0xFFB84E00));
  });

  test('dark ink on surface has contrast >= 4.5', () {
    expect(
      _contrast(AppColors.dark.ink, AppColors.dark.surface),
      greaterThanOrEqualTo(4.5),
    );
  });

  test('buildAppTheme exposes AppColors', () {
    final theme = buildAppTheme(Brightness.dark);

    expect(theme.extension<AppColors>(), AppColors.dark);
    expect(theme.textTheme.bodyMedium!.fontFamily, 'Rubik');
  });

  test('text styles set wght variation', () {
    expect(
      AppText.display.fontVariations,
      contains(const FontVariation('wght', 800)),
    );
  });
}
