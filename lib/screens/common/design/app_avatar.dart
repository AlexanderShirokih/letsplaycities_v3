import 'package:flutter/material.dart';
import 'package:lets_play_cities/screens/common/design/app_colors.dart';
import 'package:lets_play_cities/screens/common/design/app_icons.dart';
import 'package:lets_play_cities/screens/common/design/app_text.dart';
import 'package:lets_play_cities/screens/common/design/svg_path.dart';

class AppAvatar extends StatelessWidget {
  final String? pictureUrl;
  final String? initials;
  final double size;
  final bool _computer;

  const AppAvatar.user({
    super.key,
    this.pictureUrl,
    this.initials,
    this.size = 40,
  }) : _computer = false;

  const AppAvatar.computer({super.key, this.size = 40})
    : pictureUrl = null,
      initials = null,
      _computer = true;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final radius = BorderRadius.circular(size * 0.275);

    if (_computer) {
      return ExcludeSemantics(
        child: CustomPaint(
          size: Size.square(size),
          painter: _RobotPainter(c.sky, c.shadow, c.orange),
        ),
      );
    }

    Widget fallback() => Center(
      child: initials == null || initials!.isEmpty
          ? AppIcon(AppGlyph.profile, size: size * 0.55, color: c.inkSoft)
          : Text(
              initials!,
              style: AppText.section.copyWith(
                fontSize: size * 0.38,
                color: c.ink,
              ),
            ),
    );

    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: radius,
        child: Container(
          width: size,
          height: size,
          color: c.edge,
          child: pictureUrl == null
              ? fallback()
              : Image.network(
                  pictureUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => fallback(),
                ),
        ),
      ),
    );
  }
}

class _RobotPainter extends CustomPainter {
  final Color bg;
  final Color ink;
  final Color antenna;

  const _RobotPainter(this.bg, this.ink, this.antenna);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 40, size.height / 40);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 40, 40),
        const Radius.circular(11),
      ),
      Paint()..color = bg,
    );

    final head = RRect.fromRectAndRadius(
      const Rect.fromLTWH(8, 12, 24, 18),
      const Radius.circular(6),
    );
    canvas.drawRRect(head, Paint()..color = Colors.white);

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..color = ink;
    canvas.drawRRect(head, stroke);
    canvas.drawPath(parseSvgPath('M20 12V8'), stroke);
    canvas.drawPath(parseSvgPath('M17 25h6'), stroke);

    final fill = Paint()..color = ink;
    canvas.drawCircle(const Offset(15.5, 20), 2, fill);
    canvas.drawCircle(const Offset(24.5, 20), 2, fill);
    canvas.drawCircle(const Offset(20, 7), 2, Paint()..color = antenna);
  }

  @override
  bool shouldRepaint(_RobotPainter old) =>
      old.bg != bg || old.ink != ink || old.antenna != antenna;
}
