import 'package:flutter/material.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/common/design/app_colors.dart';
import 'package:lets_play_cities/screens/common/design/app_icons.dart';
import 'package:lets_play_cities/screens/common/design/app_text.dart';

class AppBottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onSelect;

  const AppBottomNav({super.key, required this.index, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final tabs = [
      (AppGlyph.play, t.design.nav.play),
      (AppGlyph.cities, t.design.nav.cities),
      (AppGlyph.profile, t.design.nav.profile),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.edge)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
            child: Row(
              children: [
                for (var i = 0; i < tabs.length; i++)
                  Expanded(
                    child: _Tab(
                      glyph: tabs[i].$1,
                      label: tabs[i].$2,
                      active: i == index,
                      onTap: () => onSelect(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final AppGlyph glyph;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _Tab({
    required this.glyph,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Semantics(
      button: true,
      selected: active,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? c.violet : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: AppIcon(
                glyph,
                size: 22,
                color: active ? Colors.white : c.inkSoft,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.small.copyWith(
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                fontVariations: [FontVariation('wght', active ? 700 : 500)],
                color: active ? c.ink : c.inkSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
