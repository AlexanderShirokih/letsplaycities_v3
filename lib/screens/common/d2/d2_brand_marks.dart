import 'package:flutter/material.dart';
import 'package:lets_play_cities/screens/common/d2/d2_text.dart';
import 'package:lets_play_cities/screens/common/d2/svg_path.dart';

/// Colors of the sign-in marks, the same in both themes
abstract final class D2BrandColors {
  static const googleRed = Color(0xFFEA4335);
  static const googleYellow = Color(0xFFFBBC05);
  static const googleGreen = Color(0xFF34A853);
  static const googleBlue = Color(0xFF4285F4);
  static const vkBlue = Color(0xFF0077FF);
  static const okOrange = Color(0xFFEE8208);
}

/// Four-colored "G" ring of the Google button (view box 24x24)
class D2GoogleMark extends StatelessWidget {
  final double size;

  const D2GoogleMark({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(size: Size.square(size), painter: _GooglePainter()),
  );
}

class _GooglePainter extends CustomPainter {
  static final _arcs = [
    ('M18.43 6.6A8.4 8.4 0 0 0 4.73 7.8', D2BrandColors.googleRed),
    ('M4.73 7.8A8.4 8.4 0 0 0 4.73 16.2', D2BrandColors.googleYellow),
    ('M4.73 16.2A8.4 8.4 0 0 0 18.43 17.4', D2BrandColors.googleGreen),
    ('M12 12h8.4A8.4 8.4 0 0 1 18.43 17.4', D2BrandColors.googleBlue),
  ].map((arc) => (parseSvgPath(arc.$1), arc.$2)).toList();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);

    for (final (path, color) in _arcs) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.4
          ..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_GooglePainter old) => false;
}

/// Blue rounded square with "VK"
class D2VkMark extends StatelessWidget {
  final double size;

  const D2VkMark({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) =>
      _D2LetterMark(label: 'VK', color: D2BrandColors.vkBlue, size: size);
}

/// Orange rounded square with "OK"
class D2OkMark extends StatelessWidget {
  final double size;

  const D2OkMark({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) =>
      _D2LetterMark(label: 'OK', color: D2BrandColors.okOrange, size: size);
}

/// A rounded square of the network color with its letters
class _D2LetterMark extends StatelessWidget {
  final String label;
  final Color color;
  final double size;

  const _D2LetterMark({
    required this.label,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: Padding(
        padding: EdgeInsets.all(size * 1.5 / 24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(size * 6.5 / 24),
          ),
          child: Center(
            child: Text(
              label,
              style: D2Text.small.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: size * 10 / 24,
                height: 1,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
