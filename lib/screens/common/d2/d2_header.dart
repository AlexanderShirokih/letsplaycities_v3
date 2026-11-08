import 'package:flutter/material.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/common/d2/d2_buttons.dart';
import 'package:lets_play_cities/screens/common/d2/d2_colors.dart';
import 'package:lets_play_cities/screens/common/d2/d2_icons.dart';
import 'package:lets_play_cities/screens/common/d2/d2_text.dart';

class D2ScreenHeader extends StatelessWidget {
  final String? title;
  final VoidCallback? onBack;
  final List<Widget> actions;

  const D2ScreenHeader({
    super.key,
    this.title,
    this.onBack,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final c = D2Colors.of(context);

    return SizedBox(
      height: 52,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            if (onBack != null)
              D2IconButton(D2Glyph.back, tooltip: t.d2.back, onPressed: onBack),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  title ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: D2Text.title.copyWith(color: c.ink),
                ),
              ),
            ),
            for (var i = 0; i < actions.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              actions[i],
            ],
          ],
        ),
      ),
    );
  }
}
