import 'package:flutter/material.dart';
import 'package:lets_play_cities/base/achievements/achievements.dart';
import 'package:lets_play_cities/i18n/enum_labels.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/common/d2/d2.dart';
import 'package:lets_play_cities/screens/profile/passport_card.dart';

/// Horizontal strip of every achievement, the received ones first
class AchievementsRow extends StatelessWidget {
  /// Whether the achievement is received
  final bool Function(Achievement) isUnlocked;

  /// Opens the leaderboard of Play Games
  final VoidCallback onRating;

  const AchievementsRow({
    super.key,
    required this.isUnlocked,
    required this.onRating,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = D2Colors.of(context);
    final all = [
      ...Achievement.values.where(isUnlocked),
      ...Achievement.values.where((a) => !isUnlocked(a)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              t.profile.achievements,
              style: D2Text.section.copyWith(color: c.ink),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ProfileLink(
                  label: t.profile.rating,
                  glyph: D2Glyph.trophy,
                  onPressed: onRating,
                ),
                const SizedBox(width: 8),
                ProfileLink(
                  label: t.profile.all,
                  onPressed: () => _showAll(context, all),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final a in all)
                _AchievementTile(achievement: a, unlocked: isUnlocked(a)),
            ],
          ),
        ),
      ],
    );
  }

  void _showAll(BuildContext context, List<Achievement> all) {
    showD2Sheet<void>(
      context,
      builder: (_) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
        child: Wrap(
          alignment: WrapAlignment.center,
          runSpacing: 12,
          children: [
            for (final a in all)
              _AchievementTile(achievement: a, unlocked: isUnlocked(a)),
          ],
        ),
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final Achievement achievement;
  final bool unlocked;

  const _AchievementTile({required this.achievement, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = D2Colors.of(context);
    final title = achievement.label(t);
    final (glyph, color) = _look(achievement, c);

    return Semantics(
      label: unlocked ? title : t.profile.achievementLocked(title: title),
      excludeSemantics: true,
      child: SizedBox(
        width: 84,
        child: Column(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: unlocked ? color : c.edge,
                borderRadius: BorderRadius.circular(14),
                border: unlocked
                    ? null
                    : Border.all(color: c.inkSoft, width: 2),
                boxShadow: unlocked
                    ? [
                        BoxShadow(
                          color: c.shadow.withValues(alpha: 0.22),
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: D2Icon(
                glyph,
                size: 24,
                color: unlocked ? c.shadow : c.inkSoft,
              ),
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: D2Text.small.copyWith(
                  height: 1.2,
                  color: unlocked ? c.ink : c.inkSoft,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static (D2Glyph, Color) _look(Achievement a, D2Colors c) => switch (a) {
    Achievement.write15Cities ||
    Achievement.write80Cities ||
    Achievement.write500Cities => (D2Glyph.cities, c.mint),
    Achievement.write50CitiesInGame ||
    Achievement.write100CitiesInGame => (D2Glyph.bolt, c.yellow),
    Achievement.use3Tips || Achievement.use30Tips => (D2Glyph.hint, c.yellow),
    Achievement.add1Friend => (D2Glyph.friends, c.sky),
    Achievement.playInHardMode => (D2Glyph.gauge, c.orange),
    Achievement.reachScore1000Pts ||
    Achievement.reachScore5000Pts ||
    Achievement.reachScore25000Pts => (D2Glyph.star, c.yellow),
    Achievement.loginViaSocial => (D2Glyph.profile, c.sky),
    Achievement.changeTheme => (D2Glyph.moon, c.sky),
    Achievement.playOnline3Times => (D2Glyph.online, c.mint),
  };
}
