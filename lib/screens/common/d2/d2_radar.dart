import 'package:flutter/material.dart';
import 'package:lets_play_cities/screens/common/d2/d2_colors.dart';

/// Three violet rings that grow and fade one after another around [center].
/// With animations disabled the rings stand still.
class D2Radar extends StatefulWidget {
  final Widget? center;
  final double size;

  const D2Radar({super.key, this.center, this.size = 160});

  @override
  State<D2Radar> createState() => _D2RadarState();
}

class _D2RadarState extends State<D2Radar> with SingleTickerProviderStateMixin {
  static const _period = Duration(milliseconds: 2400);

  /// Delay between the rings, a third of the period
  static const _ringOffset = 1 / 3;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _period,
  );

  var _animate = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final animate = !MediaQuery.disableAnimationsOf(context);
    if (animate == _animate) return;

    _animate = animate;
    if (animate) {
      _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = D2Colors.of(context);

    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _RingsPainter(
                  progress: _controller,
                  animate: _animate,
                  color: c.violet,
                  offset: _ringOffset,
                ),
              ),
            ),
            if (widget.center != null) widget.center!,
          ],
        ),
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  final Animation<double> progress;
  final bool animate;
  final Color color;
  final double offset;

  _RingsPainter({
    required this.progress,
    required this.animate,
    required this.color,
    required this.offset,
  }) : super(repaint: progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxRadius = size.shortestSide / 2 - 1;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (var i = 0; i < 3; i++) {
      final double t;
      final double scale;
      final double opacity;

      if (animate) {
        t = Curves.easeOut.transform((progress.value + i * offset) % 1);
        scale = 0.42 + 0.58 * t;
        opacity = 0.75 * (1 - t);
      } else {
        scale = 0.8;
        opacity = 0.25;
      }

      paint.color = color.withValues(alpha: opacity);
      canvas.drawCircle(center, maxRadius * scale, paint);
    }
  }

  @override
  bool shouldRepaint(_RingsPainter old) =>
      old.animate != animate || old.color != color;
}
