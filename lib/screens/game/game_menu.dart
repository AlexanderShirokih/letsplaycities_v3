import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lets_play_cities/base/game/bloc/game_bloc.dart';
import 'package:lets_play_cities/base/game/game_config.dart';
import 'package:lets_play_cities/base/game/game_mode.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/common/design/design.dart';
import 'package:lets_play_cities/screens/common/dialogs.dart';

import 'first_time_onboarding_screen.dart';
import 'hotseat_handoff.dart';

/// «Пауза» button with the game menu: «Продолжить» and «Правила игры» in the
/// local modes, «Выйти в меню» and «Сдаться…» in all of them.
///
/// The menu closes when [HotseatHandoff] covers the game.
///
/// Requires [GameBloc].
class GameMenuButton extends StatefulWidget {
  final GameConfig gameConfig;

  const GameMenuButton(this.gameConfig, {super.key});

  @override
  State<GameMenuButton> createState() => _GameMenuButtonState();
}

class _GameMenuButtonState extends State<GameMenuButton> {
  final _menu = MenuController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // The menu is drawn above the cover; it is closed after the build.
    if (HotseatHandoff.isCovering(context)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _menu.isOpen) _menu.close();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameConfig = widget.gameConfig;
    final t = context.t;
    final c = AppColors.of(context);
    final local = gameConfig.gameMode.isLocal;

    // Dialogs and routes are opened from this context: the menu items are
    // gone once the menu closes.
    void exitToMenu() => showConfirmationDialog(
      context,
      title: t.game.goToMenu,
      confirmLabel: t.game.exitConfirm,
      cancelLabel: t.game.stay,
      onOk: () => Navigator.of(context).pop(),
    );

    void surrender() => showConfirmationDialog(
      context,
      title: t.game.surrender,
      message: t.game.surrenderMessage,
      confirmLabel: t.game.surrenderConfirm,
      cancelLabel: t.game.stay,
      destructive: true,
      onOk: () => context.read<GameBloc>().add(const GameEventSurrender()),
    );

    void showRules() => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            FirstTimeOnBoardingScreen(gameConfig: gameConfig, replay: true),
      ),
    );

    return MenuAnchor(
      controller: _menu,
      alignmentOffset: const Offset(0, 8),
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(c.surface),
        shadowColor: WidgetStatePropertyAll(c.shadow.withAlpha(80)),
        elevation: const WidgetStatePropertyAll(8),
        padding: const WidgetStatePropertyAll(EdgeInsets.all(6)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      menuChildren: [
        if (local) ...[
          // Nothing to do: the menu closes when an item is activated.
          _MenuItem(AppGlyph.resume, t.game.resume, onPressed: () {}),
          _MenuItem(AppGlyph.rules, t.game.rules, onPressed: showRules),
        ],
        _MenuItem(AppGlyph.exit, t.game.exitToMenu, onPressed: exitToMenu),
        _MenuItem(
          AppGlyph.surrender,
          t.game.surrenderMenu,
          color: c.error,
          onPressed: surrender,
        ),
      ],
      builder: (context, controller, _) => AppButton(
        label: t.game.pause,
        icon: AppGlyph.pause,
        kind: AppButtonKind.secondary,
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final AppGlyph glyph;
  final String label;
  final Color? color;
  final VoidCallback onPressed;

  const _MenuItem(
    this.glyph,
    this.label, {
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final fg = color ?? AppColors.of(context).ink;

    return MenuItemButton(
      onPressed: onPressed,
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(208, 44)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 10),
        ),
        foregroundColor: WidgetStatePropertyAll(fg),
        overlayColor: WidgetStatePropertyAll(fg.withAlpha(20)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        textStyle: WidgetStatePropertyAll(AppText.body.copyWith(fontSize: 15)),
      ),
      leadingIcon: AppIcon(glyph, size: 20, color: fg),
      child: Text(label),
    );
  }
}
