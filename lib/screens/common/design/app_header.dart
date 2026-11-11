import 'package:flutter/material.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/common/design/app_buttons.dart';
import 'package:lets_play_cities/screens/common/design/app_colors.dart';
import 'package:lets_play_cities/screens/common/design/app_icons.dart';
import 'package:lets_play_cities/screens/common/design/app_text.dart';

class AppScreenHeader extends StatelessWidget {
  final String? title;
  final VoidCallback? onBack;
  final List<Widget> actions;

  const AppScreenHeader({
    super.key,
    this.title,
    this.onBack,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return SizedBox(
      height: 52,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            if (onBack != null)
              AppIconButton(AppGlyph.back, tooltip: t.design.back, onPressed: onBack),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  title ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.title.copyWith(color: c.ink),
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
