import 'package:flutter/material.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/common/d2/d2_colors.dart';
import 'package:lets_play_cities/screens/common/d2/d2_text.dart';

/// [ghost] is an empty outlined tile: a letter that does not count
enum D2TileColor { white, orange, yellow, ghost }

class D2LetterTile extends StatelessWidget {
  final String letter;
  final double size;

  /// Height of a tile that is not square, [size] by default
  final double? height;
  final D2TileColor color;

  /// Replaces «Буква хода: [letter]» for screen readers
  final String? semanticLabel;

  const D2LetterTile(
    this.letter, {
    super.key,
    this.size = 56,
    this.height,
    this.color = D2TileColor.orange,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final c = D2Colors.of(context);
    final fill = switch (color) {
      D2TileColor.white => c.surface,
      D2TileColor.orange => c.orange,
      D2TileColor.yellow => c.yellow,
      D2TileColor.ghost => null,
    };
    final onFill = switch (color) {
      D2TileColor.white => c.ink,
      D2TileColor.ghost => c.inkSoft,
      _ => D2Colors.light.ink,
    };
    final ghost = color == D2TileColor.ghost;
    final h = height ?? size;
    final shadow = h >= 44 ? 4.0 : 3.0;

    return Semantics(
      label: semanticLabel ?? t.d2.letterSemantics(letter: letter),
      excludeSemantics: true,
      child: Container(
        width: size,
        height: h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular((h * 0.22).clamp(8, 14)),
          border: Border.all(color: ghost ? c.inkSoft : c.shadow, width: 2),
          boxShadow: ghost
              ? null
              : [BoxShadow(color: c.shadow, offset: Offset(0, shadow))],
        ),
        child: Text(
          letter,
          style: D2Text.display.copyWith(
            fontSize: size * 0.5,
            height: 1,
            color: onFill,
          ),
        ),
      ),
    );
  }
}
