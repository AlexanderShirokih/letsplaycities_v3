import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/screens/common/d2/svg_path.dart';

void main() {
  test('parses absolute and relative lines', () {
    final b = parseSvgPath('M2 2h4v4H2z').getBounds();

    expect(b, const Rect.fromLTRB(2, 2, 6, 6));
  });

  test('parses arc', () {
    final b = parseSvgPath('M2 12a10 10 0 0 0 20 0').getBounds();

    expect(b.width, closeTo(20, 0.5));
    expect(b.height, closeTo(10, 0.5));
  });

  test('parses smooth cubic', () {
    final b = parseSvgPath('M0 0C0 10 10 10 10 0S20 -10 20 0').getBounds();

    expect(b.left, closeTo(0, 0.01));
    expect(b.right, closeTo(20, 0.01));
    expect(b.height, greaterThan(5));
  });

  test('parses compact numbers and relative curves', () {
    final b = parseSvgPath('M.5.5l-1-1m2 0q1 1 2 0t2 0').getBounds();

    expect(b.right, closeTo(5.5, 0.01));
  });
}
