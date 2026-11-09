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

  /// Surface with an outline and regular text, like the sign-in buttons
  outline,

  /// White with an outline on a colored card, the same in both themes
  onCard,
}

enum D2ButtonSize {
  /// Height 44
  medium,

  /// Height 48, Unbounded 15, like «Играть» on the home card
  card,

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

  /// Replaces [icon] with a mark of its own, like the Google "G"
  final Widget? leading;
  final VoidCallback? onPressed;
  final D2ButtonKind kind;
  final D2ButtonSize size;
  final bool expand;

  /// Counter in the top right corner, hidden when `null` or zero
  final int? badge;

  /// Replaces the label for screen readers
  final String? semanticLabel;

  const D2Button({
    super.key,
    required this.label,
    this.icon,
    this.leading,
    this.onPressed,
    this.kind = D2ButtonKind.primary,
    this.size = D2ButtonSize.medium,
    this.expand = false,
    this.badge,
    this.semanticLabel,
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
      D2ButtonKind.outline => (c.surface, c.shadow, c.ink, c.shadow),
      D2ButtonKind.onCard => (
        D2Colors.light.surface,
        c.shadow,
        D2Colors.light.ink,
        c.shadow,
      ),
    };

    final bordered = border != null;
    final (height, radius, fontSize, iconSize, padding) = switch (size) {
      D2ButtonSize.medium => (44.0, 14.0, 14.0, 20.0, 14.0),
      D2ButtonSize.card => (48.0, 16.0, 15.0, 20.0, 20.0),
      D2ButtonSize.large => (58.0, 18.0, 18.0, 24.0, 20.0),
    };
    final style = switch (kind) {
      D2ButtonKind.outline => D2Text.body,
      D2ButtonKind.secondary when !large => D2Text.body.copyWith(fontSize: 15),
      _ => D2Text.cta.copyWith(fontSize: fontSize),
    };
    final textColor = enabled ? fg : c.inkSoft;

    final button = _Pressable(
      color: enabled ? fill : null,
      border: enabled ? border : _disabledBorder,
      dashed: !enabled,
      shadow: enabled ? shadow : const Color(0x00000000),
      shadowHeight: !bordered ? 3 : (large ? 5 : 4),
      radius: radius,
      height: height,
      width: expand ? double.infinity : null,
      onPressed: onPressed,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: padding),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 12),
            ] else if (icon != null) ...[
              D2Icon(icon!, size: iconSize, color: textColor),
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
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      excludeSemantics: semanticLabel != null,
      onTap: semanticLabel != null ? onPressed : null,
      child: badge == null || badge! <= 0
          ? button
          : Stack(
              clipBehavior: Clip.none,
              children: [
                button,
                Positioned(top: -4, right: -4, child: _Badge(badge!)),
              ],
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
              Positioned(top: -4, right: -4, child: _Badge(badge!)),
          ],
        ),
      ),
    );
  }
}

/// Orange counter on the corner of a button
class _Badge extends StatelessWidget {
  final int count;

  const _Badge(this.count);

  @override
  Widget build(BuildContext context) {
    final c = D2Colors.of(context);

    return Container(
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
        '$count',
        style: D2Text.small.copyWith(
          fontSize: 11,
          height: 1,
          color: D2Colors.light.ink,
        ),
      ),
    );
  }
}

/// Violet button with only a white glyph, like «Отправить».
/// [tooltip] is its semantics label.
class D2SquareButton extends StatelessWidget {
  final D2Glyph glyph;
  final String tooltip;
  final VoidCallback? onPressed;
  final double width;
  final double height;

  const D2SquareButton(
    this.glyph, {
    super.key,
    required this.tooltip,
    this.onPressed,
    this.width = 56,
    this.height = 52,
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
      child: _Pressable(
        color: enabled ? c.violet : null,
        border: enabled ? c.shadow : _disabledBorder,
        dashed: !enabled,
        shadow: enabled ? c.shadow : const Color(0x00000000),
        shadowHeight: 4,
        radius: 16,
        width: width,
        height: height,
        onPressed: onPressed,
        child: Center(
          child: D2Icon(
            glyph,
            size: 26,
            strokeWidth: 3,
            color: enabled ? Colors.white : c.inkSoft,
          ),
        ),
      ),
    );
  }
}
