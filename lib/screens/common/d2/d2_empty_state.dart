import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lets_play_cities/screens/common/d2/d2_buttons.dart';
import 'package:lets_play_cities/screens/common/d2/d2_colors.dart';
import 'package:lets_play_cities/screens/common/d2/d2_icons.dart';
import 'package:lets_play_cities/screens/common/d2/d2_text.dart';

/// A screen state without content: [art], [title], an optional [text] and
/// [extra] under it, and an optional large button at the bottom. Fills the
/// space it is given; the middle part scrolls when it does not fit.
class D2EmptyState extends StatelessWidget {
  final Widget art;
  final String title;
  final String? text;

  /// Goes under the text, like the details of an error
  final Widget? extra;

  /// Label of the bottom button; the button is hidden when `null`
  final String? actionLabel;
  final D2Glyph? actionIcon;
  final VoidCallback? onAction;

  /// Goes under the bottom button, like a secondary button
  final Widget? secondaryAction;

  const D2EmptyState({
    super.key,
    required this.art,
    required this.title,
    this.text,
    this.extra,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.secondaryAction,
  });

  @override
  Widget build(BuildContext context) {
    final c = D2Colors.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ExcludeSemantics(child: FittedBox(child: art)),
                    const SizedBox(height: 24),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: D2Text.display.copyWith(
                        fontSize: 24,
                        color: c.ink,
                      ),
                    ),
                    if (text != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        text!,
                        textAlign: TextAlign.center,
                        style: D2Text.bodyRegular.copyWith(
                          fontSize: 16,
                          height: 1.4,
                          color: c.inkSoft,
                        ),
                      ),
                    ],
                    if (extra != null) ...[const SizedBox(height: 20), extra!],
                  ],
                ),
              ),
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 12),
            D2Button(
              label: actionLabel!,
              icon: actionIcon,
              size: D2ButtonSize.large,
              expand: true,
              onPressed: onAction,
            ),
          ],
          if (secondaryAction != null) ...[
            const SizedBox(height: 14),
            secondaryAction!,
          ],
        ],
      ),
    );
  }
}

/// Art of an empty state: a tilted tile with [glyph] on a pale circle, an
/// optional round [badge] at its corner and three bits of confetti.
class D2TileArt extends StatelessWidget {
  final D2Glyph glyph;

  /// Glyph of the orange mark at the top right corner of the tile
  final D2Glyph? badge;

  /// Fill of the tile, the surface color by default
  final Color? tileColor;

  const D2TileArt({super.key, required this.glyph, this.badge, this.tileColor});

  @override
  Widget build(BuildContext context) {
    final c = D2Colors.of(context);
    final onTile = tileColor == null ? c.ink : D2Colors.light.ink;

    return SizedBox(
      width: 220,
      height: 150,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned(left: 42, top: 10, child: _Halo()),
          Positioned(
            left: 68,
            top: 36,
            child: Transform.rotate(
              angle: -6 * pi / 180,
              child: Container(
                width: 84,
                height: 84,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tileColor ?? c.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: c.shadow, width: 2.5),
                  boxShadow: [
                    BoxShadow(color: c.shadow, offset: const Offset(0, 6)),
                  ],
                ),
                child: D2Icon(
                  glyph,
                  size: 48,
                  color: onTile,
                  strokeWidth: 2.25,
                ),
              ),
            ),
          ),
          if (badge != null)
            Positioned(
              left: 131,
              top: 26,
              child: Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.orange,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.shadow, width: 2.5),
                  boxShadow: [
                    BoxShadow(color: c.shadow, offset: const Offset(0, 4)),
                  ],
                ),
                child: D2Icon(badge!, size: 22, color: D2Colors.light.ink),
              ),
            ),
          Positioned(
            left: 34,
            top: 92,
            child: _Bit(color: c.yellow, size: 12, radius: 3, degrees: -16),
          ),
          Positioned(left: 173, top: 107, child: _Bit(color: c.violet)),
          Positioned(left: 48, top: 34, child: _Bit(color: c.mint, size: 8)),
        ],
      ),
    );
  }
}

/// Art of the empty statistics: three growing bars on a pale circle
class D2BarsArt extends StatelessWidget {
  const D2BarsArt({super.key});

  @override
  Widget build(BuildContext context) {
    final c = D2Colors.of(context);

    Widget bar(double left, double height, Color color) => Positioned(
      left: left,
      top: 122 - height,
      child: Container(
        width: 34,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: c.shadow, width: 2.5),
          boxShadow: [BoxShadow(color: c.shadow, offset: const Offset(0, 5))],
        ),
      ),
    );

    return SizedBox(
      width: 220,
      height: 150,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned(left: 42, top: 12, child: _Halo()),
          bar(48, 44, c.surface),
          bar(93, 70, c.yellow),
          bar(138, 96, c.orange),
          Positioned(
            left: 62,
            top: 34,
            child: _Bit(color: c.violet, size: 12, radius: 3, degrees: 18),
          ),
          Positioned(left: 105, top: 21, child: _Bit(color: c.mint)),
          Positioned(
            left: 188,
            top: 54,
            child: _Bit(color: c.surface, size: 8),
          ),
        ],
      ),
    );
  }
}

/// Pale circle behind the art
class _Halo extends StatelessWidget {
  const _Halo();

  @override
  Widget build(BuildContext context) => Container(
    width: 136,
    height: 136,
    decoration: BoxDecoration(
      color: D2Colors.of(context).surface.withValues(alpha: 0.6),
      shape: BoxShape.circle,
    ),
  );
}

/// A bit of confetti: a circle, or a tilted square when [radius] is set
class _Bit extends StatelessWidget {
  final Color color;
  final double size;
  final double? radius;
  final double degrees;

  const _Bit({
    required this.color,
    this.size = 10,
    this.radius,
    this.degrees = 0,
  });

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: degrees * pi / 180,
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: radius == null ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: radius == null ? null : BorderRadius.circular(radius!),
        border: Border.all(color: D2Colors.of(context).shadow, width: 2),
      ),
    ),
  );
}
