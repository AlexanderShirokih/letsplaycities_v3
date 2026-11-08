import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/screens/common/theme_mode.dart';
import 'package:lets_play_cities/base/achievements/achievements.dart';
import 'package:lets_play_cities/base/achievements/achievements_service.dart';
import 'package:lets_play_cities/base/dictionary.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/base/scoring.dart';
import 'package:lets_play_cities/base/themes/app_theme_mode.dart';
import 'package:lets_play_cities/i18n/enum_labels.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/common/d2/d2.dart';
import 'package:lets_play_cities/screens/settings/settings_mapping.dart';
import 'package:lets_play_cities/screens/settings/stats/stats_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  /// Writes a preference and redraws the screen with the new value
  void _set(VoidCallback write) => setState(write);

  /// Applies [mode]; choosing another mode than the current one counts for
  /// [Achievement.changeTheme].
  void _setThemeMode(AppThemeMode mode) {
    if (mode == context.read<GamePreferences>().themeMode) return;

    _set(() => setThemeMode(mode));
    unawaited(
      GetIt.instance.get<AchievementsService>().unlockAchievement(
        Achievement.changeTheme,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final prefs = context.read<GamePreferences>();
    final c = D2Colors.of(context);
    final titles = t.settings.settingsItemTitles;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            D2ScreenHeader(
              title: t.settings.settings,
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                children: [
                  _Group(
                    title: t.settings.groups.game,
                    children: [
                      _ChoiceRow(
                        glyph: D2Glyph.gauge,
                        label: titles.difficulty,
                        child: D2Segmented<Difficulty>(
                          items: [
                            for (final d in Difficulty.values) (d, d.label(t)),
                          ],
                          selected: prefs.wordsDifficulty,
                          onChanged: (d) =>
                              _set(() => prefs.wordsDifficulty = d),
                        ),
                      ),
                      _ChoiceRow(
                        glyph: D2Glyph.timer,
                        label: titles.moveTimer,
                        child: D2Segmented<int>(
                          items: [
                            (30, t.settings.timer.s30),
                            (60, t.settings.timer.m1),
                            (120, t.settings.timer.m2),
                            (0, t.settings.timer.off),
                          ],
                          selected: timerOptionFor(prefs.timeLimit),
                          onChanged: (s) => _set(() => prefs.timeLimit = s),
                        ),
                      ),
                      _ChoiceRow(
                        glyph: D2Glyph.star,
                        label: titles.scoring,
                        child: D2Segmented<ScoringType>(
                          items: [
                            for (final s in ScoringType.values) (s, s.label(t)),
                          ],
                          selected: prefs.scoringType,
                          onChanged: (s) => _set(() => prefs.scoringType = s),
                        ),
                      ),
                      _SwitchRow(
                        glyph: D2Glyph.wand,
                        label: titles.correction,
                        value: prefs.correctionEnabled,
                        onChanged: (v) =>
                            _set(() => prefs.correctionEnabled = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _Group(
                    title: t.settings.groups.online,
                    children: [
                      _SwitchRow(
                        glyph: D2Glyph.chat,
                        label: titles.onlineChat,
                        value: prefs.onlineChatEnabled,
                        onChanged: (v) =>
                            _set(() => prefs.onlineChatEnabled = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _Group(
                    title: t.settings.groups.app,
                    children: [
                      _SwitchRow(
                        glyph: D2Glyph.sound,
                        label: titles.sound,
                        value: prefs.soundEnabled,
                        onChanged: (v) => _set(() => prefs.soundEnabled = v),
                      ),
                      _ChoiceRow(
                        glyph: D2Glyph.moon,
                        label: titles.theme,
                        child: D2Segmented<AppThemeMode>(
                          items: [
                            (AppThemeMode.light, t.settings.themeMode.light),
                            (AppThemeMode.dark, t.settings.themeMode.dark),
                            (AppThemeMode.system, t.settings.themeMode.system),
                          ],
                          selected: prefs.themeMode,
                          onChanged: _setThemeMode,
                        ),
                      ),
                      _SwitchRow(
                        glyph: D2Glyph.rules,
                        label: titles.dictUpdates,
                        value: dictionaryUpdatesOn(
                          prefs.dictionaryUpdatePeriod,
                        ),
                        onChanged: (v) => _set(
                          () => prefs.dictionaryUpdatePeriod =
                              dictionaryPeriodFor(v),
                        ),
                      ),
                      _NavigationRow(
                        glyph: D2Glyph.trophy,
                        label: t.settings.stats,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => StatisticsScreen()),
                        ),
                      ),
                      _NavigationRow(
                        glyph: D2Glyph.globe,
                        label: t.settings.licenses,
                        onTap: () => showLicensePage(context: context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Group({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final c = D2Colors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title, style: D2Text.section.copyWith(color: c.ink)),
        ),
        D2Card(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) Container(height: 2, color: c.bg),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _RowIcon extends StatelessWidget {
  final D2Glyph glyph;

  const _RowIcon(this.glyph);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: D2Colors.of(context).bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: D2Icon(glyph, size: 20),
    );
  }
}

class _RowLabel extends StatelessWidget {
  final String text;

  const _RowLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        text,
        style: D2Text.body.copyWith(color: D2Colors.of(context).ink),
      ),
    );
  }
}

/// Label with a control below it
class _ChoiceRow extends StatelessWidget {
  final D2Glyph glyph;
  final String label;
  final Widget child;

  const _ChoiceRow({
    required this.glyph,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 40,
            child: Row(
              children: [
                _RowIcon(glyph),
                const SizedBox(width: 12),
                _RowLabel(label),
              ],
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final D2Glyph glyph;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.glyph,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 6, 0),
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            _RowIcon(glyph),
            const SizedBox(width: 12),
            _RowLabel(label),
            D2Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

class _NavigationRow extends StatelessWidget {
  final D2Glyph glyph;
  final String label;
  final VoidCallback onTap;

  const _NavigationRow({
    required this.glyph,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 14, 0),
          child: SizedBox(
            height: 52,
            child: Row(
              children: [
                _RowIcon(glyph),
                const SizedBox(width: 12),
                _RowLabel(label),
                const RotatedBox(quarterTurns: 2, child: D2Icon(D2Glyph.back)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
