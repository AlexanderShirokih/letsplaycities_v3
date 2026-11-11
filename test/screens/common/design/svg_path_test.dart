import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/screens/common/design/svg_path.dart';

Offset _mid(Path p) {
  final m = p.computeMetrics().first;

  return m.getTangentForOffset(m.length / 2)!.position;
}

void _same(Path a, Path b) {
  expect(_mid(a).dx, closeTo(_mid(b).dx, 0.01));
  expect(_mid(a).dy, closeTo(_mid(b).dy, 0.01));
  expect(a.getBounds().left, closeTo(b.getBounds().left, 0.01));
  expect(a.getBounds().right, closeTo(b.getBounds().right, 0.01));
  expect(a.getBounds().top, closeTo(b.getBounds().top, 0.01));
  expect(a.getBounds().bottom, closeTo(b.getBounds().bottom, 0.01));
}

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

  test('arc sweep flag picks the side', () {
    final up = _mid(parseSvgPath('M0 0A5 5 0 0 1 10 0'));
    final down = _mid(parseSvgPath('M0 0A5 5 0 0 0 10 0'));

    expect(up.dx, closeTo(5, 0.05));
    expect(up.dy, closeTo(-5, 0.05));
    expect(down.dx, closeTo(5, 0.05));
    expect(down.dy, closeTo(5, 0.05));
  });

  test('arc large-arc flag picks the longer way', () {
    final small = parseSvgPath('M0 0A10 10 0 0 1 10 0').getBounds();
    final large = parseSvgPath('M0 0A10 10 0 1 1 10 0').getBounds();

    expect(large.height, greaterThan(small.height + 5));
    expect(large.width, greaterThan(small.width));
  });

  test('relative arc equals absolute arc', () {
    _same(
      parseSvgPath('M3 4a5 5 0 0 1 10 0'),
      parseSvgPath('M3 4A5 5 0 0 1 13 4'),
    );
  });

  test('arc flags may be glued to the next number', () {
    _same(parseSvgPath('M0 0a5 5 0 105 5'), parseSvgPath('M0 0a5 5 0 1 0 5 5'));
  });

  test('arc radius is scaled up when too small', () {
    final b = parseSvgPath('M0 0A1 1 0 0 1 10 0').getBounds();

    expect(b.width, closeTo(10, 0.05));
    expect(b.height, closeTo(5, 0.05));
  });

  test('arc x-axis rotation is in degrees', () {
    final rotated = parseSvgPath('M5 0A10 5 90 1 1 5 10').getBounds();
    final swapped = parseSvgPath('M5 0A5 10 0 1 1 5 10').getBounds();
    final plain = parseSvgPath('M5 0A10 5 0 1 1 5 10').getBounds();

    expect(rotated.width, closeTo(swapped.width, 0.05));
    expect(rotated.height, closeTo(swapped.height, 0.05));
    expect((rotated.width - plain.width).abs(), greaterThan(1));
  });

  test('parses smooth cubic', () {
    final b = parseSvgPath('M0 0C0 10 10 10 10 0S20 -10 20 0').getBounds();

    expect(b.left, closeTo(0, 0.01));
    expect(b.right, closeTo(20, 0.01));
    expect(b.height, greaterThan(5));
  });

  test('S reflects the control point after C, else uses current point', () {
    final afterC = parseSvgPath('M0 0C0 10 10 10 10 0S20 -10 20 0');
    final afterL = parseSvgPath('M0 0L10 0S20 -10 20 0');

    _same(afterC, parseSvgPath('M0 0C0 10 10 10 10 0C10 -10 20 -10 20 0'));
    _same(afterL, parseSvgPath('M0 0L10 0C10 0 20 -10 20 0'));
    expect(
      (_mid(afterC).dy - _mid(parseSvgPath('M0 0L10 0S20 -10 20 0')).dy).abs(),
      greaterThan(0.5),
    );
  });

  test('T reflects the control point after Q, else uses current point', () {
    final afterQ = parseSvgPath('M0 0Q5 10 10 0T20 0');
    final afterL = parseSvgPath('M0 0L10 0T20 0');

    _same(afterQ, parseSvgPath('M0 0Q5 10 10 0Q15 -10 20 0'));
    _same(afterL, parseSvgPath('M0 0L10 0Q10 0 20 0'));
    expect(afterQ.getBounds().height, greaterThan(afterL.getBounds().height));
  });

  test('parses compact numbers and relative curves', () {
    final b = parseSvgPath('M.5.5l-1-1m2 0q1 1 2 0t2 0').getBounds();

    expect(b.right, closeTo(5.5, 0.01));
  });

  test('throws FormatException on malformed input', () {
    expect(() => parseSvgPath('10 10'), throwsFormatException);
    expect(() => parseSvgPath('M0 0L5'), throwsFormatException);
    expect(() => parseSvgPath('M0 0X5 5'), throwsFormatException);
    expect(() => parseSvgPath('M0 0A5 5 0 2 0 5 5'), throwsFormatException);
  });
}
