import 'package:flutter/material.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/common/d2/d2_colors.dart';
import 'package:lets_play_cities/screens/common/d2/d2_text.dart';

enum D2TileColor { white, orange, yellow }

class D2LetterTile extends StatelessWidget {
  final String letter;
  final double size;
  final D2TileColor color;

  const D2LetterTile(
    this.letter, {
    super.key,
    this.size = 56,
    this.color = D2TileColor.orange,
  });

  @override
  Widget build(BuildContext context) {
    final c = D2Colors.of(context);
    final fill = switch (color) {
      D2TileColor.white => c.surface,
      D2TileColor.orange => c.orange,
      D2TileColor.yellow => c.yellow,
    };
    final onFill = color == D2TileColor.white ? c.ink : D2Colors.light.ink;
    final shadow = size >= 48 ? 4.0 : 3.0;

    return Semantics(
      label: t.d2.letterSemantics(letter: letter),
      excludeSemantics: true,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular((size * 0.22).clamp(8, 14)),
          border: Border.all(color: c.shadow, width: 2),
          boxShadow: [BoxShadow(color: c.shadow, offset: Offset(0, shadow))],
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
