import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lets_play_cities/screens/common/d2/d2_colors.dart';

/// Ring with an arc of [progress] (0..1) clockwise from 12 o'clock
class D2TimerRing extends StatelessWidget {
  final double progress;
  final Widget child;
  final double size;

  const D2TimerRing({
    super.key,
    required this.progress,
    required this.child,
    this.size = 104,
  });

  @override
  Widget build(BuildContext context) {
    final c = D2Colors.of(context);

    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _RingPainter(progress.clamp(0, 1), c.edge, c.orange),
        child: Center(child: child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  static const _width = 8.0;

  final double progress;
  final Color track;
  final Color arc;

  const _RingPainter(this.progress, this.track, this.arc);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(_width / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _width
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 0, 2 * math.pi, false, paint..color = track);
    if (progress > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        paint..color = arc,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.track != track || old.arc != arc;
}
