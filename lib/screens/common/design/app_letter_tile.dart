import 'package:flutter/material.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/common/design/app_colors.dart';
import 'package:lets_play_cities/screens/common/design/app_text.dart';

/// [ghost] is an empty outlined tile: a letter that does not count
enum AppTileColor { white, orange, yellow, ghost }

class AppLetterTile extends StatelessWidget {
  final String letter;
  final double size;

  /// Height of a tile that is not square, [size] by default
  final double? height;
  final AppTileColor color;

  /// Replaces «Буква хода: [letter]» for screen readers
  final String? semanticLabel;

  const AppLetterTile(
    this.letter, {
    super.key,
    this.size = 56,
    this.height,
    this.color = AppTileColor.orange,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final fill = switch (color) {
      AppTileColor.white => c.surface,
      AppTileColor.orange => c.orange,
      AppTileColor.yellow => c.yellow,
      AppTileColor.ghost => null,
    };
    final onFill = switch (color) {
      AppTileColor.white => c.ink,
      AppTileColor.ghost => c.inkSoft,
      _ => AppColors.light.ink,
    };
    final ghost = color == AppTileColor.ghost;
    final h = height ?? size;
    final shadow = h >= 44 ? 4.0 : 3.0;

    return Semantics(
      label: semanticLabel ?? t.design.letterSemantics(letter: letter),
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
          style: AppText.display.copyWith(
            fontSize: size * 0.5,
            height: 1,
            color: onFill,
          ),
        ),
      ),
    );
  }
}
