import 'package:flutter/material.dart';
import 'package:lets_play_cities/screens/common/d2/d2.dart';

/// Search input of the cities screens: a rounded box with a magnifier.
/// [flat] drops the shadow and fills the box with the page color, for use on
/// a surface-colored sheet.
class D2SearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  final bool flat;

  const D2SearchField({
    super.key,
    required this.hint,
    required this.onChanged,
    this.flat = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = D2Colors.of(context);
    final style = D2Text.body.copyWith(color: c.ink);

    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: flat ? c.bg : c.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: flat
            ? null
            : [BoxShadow(color: c.edge, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          D2Icon(D2Glyph.search, size: 22, color: c.inkSoft),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              cursorColor: c.violet,
              style: style,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: style.copyWith(color: c.inkSoft),
                hintMaxLines: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
