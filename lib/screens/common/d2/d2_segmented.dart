import 'package:flutter/material.dart';
import 'package:lets_play_cities/screens/common/d2/d2_colors.dart';
import 'package:lets_play_cities/screens/common/d2/d2_icons.dart';
import 'package:lets_play_cities/screens/common/d2/d2_text.dart';

class D2Segmented<T> extends StatelessWidget {
  final List<(T, String)> items;
  final T? selected;
  final ValueChanged<T> onChanged;

  /// Glyphs shown before the labels of the items that have one
  final Map<T, D2Glyph> icons;

  const D2Segmented({
    super.key,
    required this.items,
    required this.selected,
    required this.onChanged,
    this.icons = const {},
  });

  @override
  Widget build(BuildContext context) {
    final c = D2Colors.of(context);

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final (value, label) in items)
            Expanded(
              child: Semantics(
                button: true,
                selected: value == selected,
                inMutuallyExclusiveGroup: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(value),
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: value == selected ? c.violet : null,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icons[value] case final glyph?) ...[
                            D2Icon(
                              glyph,
                              size: 20,
                              color: value == selected
                                  ? Colors.white
                                  : c.inkSoft,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            label,
                            maxLines: 1,
                            style: D2Text.body.copyWith(
                              fontSize: 14,
                              color: value == selected
                                  ? Colors.white
                                  : c.inkSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
