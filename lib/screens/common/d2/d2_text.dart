import 'package:flutter/painting.dart';

/// D2 text styles. The fonts are variable, so each style sets both the
/// weight and the `wght` variation.
abstract final class D2Text {
  static const unbounded = 'Unbounded';
  static const rubik = 'Rubik';

  static final display = _style(unbounded, 800, 28);
  static final title = _style(unbounded, 700, 18);
  static final cta = _style(unbounded, 700, 18);
  static final score = _style(unbounded, 800, 24);
  static final section = _style(unbounded, 700, 15);
  static final body = _style(rubik, 500, 16);
  static final bodyRegular = _style(rubik, 400, 15);
  static final caption = _style(rubik, 400, 13);
  static final small = _style(rubik, 500, 12);

  static TextStyle _style(String family, int weight, double size) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.values[weight ~/ 100 - 1],
    fontVariations: [FontVariation('wght', weight.toDouble())],
  );
}
