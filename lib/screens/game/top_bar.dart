import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lets_play_cities/base/game/bloc/game_bloc.dart';
import 'package:lets_play_cities/base/game/game_config.dart';
import 'package:lets_play_cities/base/repos.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/common/d2/d2.dart';
import 'package:lets_play_cities/screens/common/dialogs.dart';

import 'chat_sheet.dart';
import 'game_menu.dart';

/// The row above the score: «Пауза» on the left, «Подсказка» against the
/// computer or «Чат» in the network game on the right.
class TopBar extends StatelessWidget {
  final GameConfig gameConfig;

  const TopBar(this.gameConfig, {super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final repo = context.watch<GameSessionRepository>();

    return SizedBox(
      height: 52,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: GameMenuButton(gameConfig)),
            const SizedBox(width: 8),
            if (repo.helpAvailable)
              Flexible(
                child: D2Button(
                  label: t.game.hint,
                  icon: D2Glyph.hint,
                  kind: D2ButtonKind.hint,
                  onPressed: () => showConfirmationDialog(
                    context,
                    message: t.game.showHelp,
                    onOk: () =>
                        context.read<GameBloc>().add(const GameEventShowHelp()),
                  ),
                ),
              )
            else if (repo.messagingAvailable)
              const Flexible(child: ChatButton()),
          ],
        ),
      ),
    );
  }
}
