import 'package:flutter/material.dart';
import 'package:lets_play_cities/screens/common/d2/d2_colors.dart';
import 'package:lets_play_cities/screens/common/d2/d2_icons.dart';
import 'package:lets_play_cities/screens/common/d2/d2_text.dart';

/// Border of a disabled button
const _disabledBorder = Color(0xFFB9AEF0);

enum D2ButtonKind {
  /// Orange with an outline
  primary,

  /// Violet with an outline and white text
  accent,

  /// Surface without an outline
  secondary,

  /// Yellow without an outline
  hint,
}

enum D2ButtonSize {
  /// Height 44
  medium,

  /// Height 58, Unbounded 18
  large,
}

/// A box with a hard shadow that sinks by the shadow height when pressed
class _Pressable extends StatefulWidget {
  final Color? color;
  final Color? border;
  final Color shadow;
  final double shadowHeight;
  final double radius;
  final double? width;
  final double height;
  final bool dashed;
  final VoidCallback? onPressed;
  final Widget child;

  const _Pressable({
    required this.color,
    required this.border,
    required this.shadow,
    required this.shadowHeight,
    required this.radius,
    required this.height,
    required this.onPressed,
    required this.child,
    this.width,
    this.dashed = false,
  });

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  var _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final sunk = _down && enabled;
    final sh = widget.shadowHeight;
    final radius = BorderRadius.circular(widget.radius);

    return Padding(
      padding: EdgeInsets.only(bottom: sh),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _set(true) : null,
        onTapUp: enabled ? (_) => _set(false) : null,
        onTapCancel: enabled ? () => _set(false) : null,
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          width: widget.width,
          height: widget.height,
          transform: Matrix4.translationValues(0, sunk ? sh : 0, 0),
          foregroundDecoration: widget.dashed
              ? _DashedBorder(widget.border!, widget.radius)
              : null,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: radius,
            border: !widget.dashed && widget.border != null
                ? Border.all(color: widget.border!, width: 2)
                : null,
            boxShadow: [
              BoxShadow(color: widget.shadow, offset: Offset(0, sunk ? 0 : sh)),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class _DashedBorder extends Decoration {
  final Color color;
  final double radius;

  const _DashedBorder(this.color, this.radius);

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _DashedPainter(color, radius);
}

class _DashedPainter extends BoxPainter {
  final Color color;
  final double radius;

  _DashedPainter(this.color, this.radius);

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size;
    if (size == null) return;

    final rect = (offset & size).deflate(1);
    final source = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (final metric in source.computeMetrics()) {
      for (var pos = 0.0; pos < metric.length; pos += 10) {
        canvas.drawPath(
          metric.extractPath(pos, (pos + 6).clamp(0, metric.length)),
          paint,
        );
      }
    }
  }
}

class D2Button extends StatelessWidget {
  final String label;
  final D2Glyph? icon;
  final VoidCallback? onPressed;
  final D2ButtonKind kind;
  final D2ButtonSize size;
  final bool expand;

  const D2Button({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.kind = D2ButtonKind.primary,
    this.size = D2ButtonSize.medium,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = D2Colors.of(context);
    final large = size == D2ButtonSize.large;
    final enabled = onPressed != null;

    final (fill, border, fg, shadow) = switch (kind) {
      D2ButtonKind.primary => (c.orange, c.shadow, c.ink, c.shadow),
      D2ButtonKind.accent => (c.violet, c.shadow, Colors.white, c.shadow),
      D2ButtonKind.secondary => (c.surface, null, c.ink, c.edge),
      D2ButtonKind.hint => (
        c.yellow,
        null,
        D2Colors.light.ink,
        c.shadow.withAlpha(56),
      ),
    };

    final bordered = border != null;
    final fontSize = large ? 18.0 : 14.0;
    final style = kind == D2ButtonKind.secondary && !large
        ? D2Text.body.copyWith(fontSize: 15)
        : D2Text.cta.copyWith(fontSize: fontSize);
    final textColor = enabled ? fg : c.inkSoft;

    return Semantics(
      button: true,
      enabled: enabled,
      child: _Pressable(
        color: enabled ? fill : null,
        border: enabled ? border : _disabledBorder,
        dashed: !enabled,
        shadow: enabled ? shadow : const Color(0x00000000),
        shadowHeight: !bordered ? 3 : (large ? 5 : 4),
        radius: large ? 18 : 14,
        height: large ? 58 : 44,
        width: expand ? double.infinity : null,
        onPressed: onPressed,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: large ? 20 : 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                D2Icon(icon!, size: large ? 24 : 20, color: textColor),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style.copyWith(color: textColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 44x44 icon button. [tooltip] is also its semantics label.
class D2IconButton extends StatelessWidget {
  final D2Glyph glyph;
  final String tooltip;
  final VoidCallback? onPressed;
  final int? badge;

  const D2IconButton(
    this.glyph, {
    super.key,
    required this.tooltip,
    this.onPressed,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final c = D2Colors.of(context);
    final enabled = onPressed != null;

    return Semantics(
      label: tooltip,
      button: true,
      enabled: enabled,
      excludeSemantics: true,
      onTap: onPressed,
      child: Tooltip(
        message: tooltip,
        excludeFromSemantics: true,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            _Pressable(
              color: c.surface,
              border: null,
              shadow: c.edge,
              shadowHeight: 3,
              radius: 14,
              width: 44,
              height: 44,
              onPressed: onPressed,
              child: Center(
                child: D2Icon(
                  glyph,
                  size: 22,
                  color: enabled ? c.ink : c.inkSoft,
                ),
              ),
            ),
            if (badge != null && badge! > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 18),
                  height: 18,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.orange,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: c.surface, width: 2),
                  ),
                  child: Text(
                    '$badge',
                    style: D2Text.small.copyWith(
                      fontSize: 11,
                      height: 1,
                      color: D2Colors.light.ink,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
