import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/screens/common/d2/d2_colors.dart';
import 'package:lets_play_cities/screens/common/d2/d2_text.dart';
import 'package:lets_play_cities/screens/common/d2/d2_theme.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;

  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  test('light tokens match spec', () {
    expect(D2Colors.light.bg, const Color(0xFFF1EEFF));
    expect(D2Colors.light.ink, const Color(0xFF1B1340));
    expect(D2Colors.light.orange, const Color(0xFFFF7A1A));
    expect(D2Colors.light.violet, const Color(0xFF5B3DF5));
    expect(D2Colors.light.letter, const Color(0xFFB84E00));
  });

  test('dark ink on surface has contrast >= 4.5', () {
    expect(
      _contrast(D2Colors.dark.ink, D2Colors.dark.surface),
      greaterThanOrEqualTo(4.5),
    );
  });

  test('buildD2Theme exposes D2Colors', () {
    final theme = buildD2Theme(Brightness.dark);

    expect(theme.extension<D2Colors>(), D2Colors.dark);
    expect(theme.textTheme.bodyMedium!.fontFamily, 'Rubik');
  });

  test('text styles set wght variation', () {
    expect(
      D2Text.display.fontVariations,
      contains(const FontVariation('wght', 800)),
    );
  });
}
