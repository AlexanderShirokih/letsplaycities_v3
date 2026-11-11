import 'package:flutter/material.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/common/design/app_colors.dart';
import 'package:lets_play_cities/screens/common/design/app_text.dart';

/// Logo of two tiles, "Г" and "А" (view box 100x100)
class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 116});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Semantics(
      label: t.design.logoSemantics,
      image: true,
      excludeSemantics: true,
      child: CustomPaint(size: Size.square(size), painter: _LogoPainter(c)),
    );
  }
}

class _LogoPainter extends CustomPainter {
  final AppColors c;

  const _LogoPainter(this.c);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100, size.height / 100);

    _tile(canvas, 6, 4, c.surface, 'Г', 32, 39.75);
    _tile(canvas, 40, 38, c.orange, 'А', 66, 73.75);
  }

  void _tile(
    Canvas canvas,
    double x,
    double y,
    Color fill,
    String letter,
    double textX,
    double baseline,
  ) {
    RRect rect(double dy) => RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y + dy, 52, 52),
      const Radius.circular(12),
    );

    canvas.drawRRect(rect(5), Paint()..color = c.shadow);
    canvas.drawRRect(rect(0), Paint()..color = fill);
    canvas.drawRRect(
      rect(0),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = c.shadow,
    );

    final painter = TextPainter(
      text: TextSpan(
        text: letter,
        style: AppText.title.copyWith(
          fontSize: 26,
          color: fill == c.surface ? c.ink : AppColors.light.ink,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final ascent = painter.computeDistanceToActualBaseline(
      TextBaseline.alphabetic,
    );
    painter.paint(canvas, Offset(textX - painter.width / 2, baseline - ascent));
  }

  @override
  bool shouldRepaint(_LogoPainter old) => old.c != c;
}
