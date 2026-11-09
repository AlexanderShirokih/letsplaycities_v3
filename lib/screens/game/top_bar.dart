import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lets_play_cities/base/game/bloc/game_bloc.dart';
import 'package:lets_play_cities/base/game/game_config.dart';
import 'package:lets_play_cities/base/repos.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/common/d2/d2.dart';
import 'package:lets_play_cities/screens/common/dialogs.dart';
import 'package:lets_play_cities/utils/minutes_seconds.dart';

import 'chat_sheet.dart';
import 'game_menu.dart';

/// The row above the score: «Пауза» on the left, «Подсказка» against the
/// computer or «Чат» in the network game on the right.
class TopBar extends StatelessWidget {
  final GameConfig gameConfig;

  const TopBar(this.gameConfig, {super.key});

  @override
  Widget build(BuildContext context) {
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
              Flexible(child: _HintButton(repo.hintReadyAt))
            else if (repo.messagingAvailable)
              const Flexible(child: ChatButton()),
          ],
        ),
      ),
    );
  }
}

/// «Подсказка», or the time left until the next one while it is disabled
class _HintButton extends StatefulWidget {
  final ValueListenable<DateTime?> readyAt;

  const _HintButton(this.readyAt);

  @override
  State<_HintButton> createState() => _HintButtonState();
}

class _HintButtonState extends State<_HintButton> {
  static const _minWidth = 150.0;

  Timer? _ticks;

  @override
  void initState() {
    super.initState();
    widget.readyAt.addListener(_onReadyAt);
    _onReadyAt();
  }

  @override
  void dispose() {
    widget.readyAt.removeListener(_onReadyAt);
    _ticks?.cancel();
    super.dispose();
  }

  /// Seconds until the next hint, 0 when it is ready
  int get _secondsLeft {
    final readyAt = widget.readyAt.value;
    if (readyAt == null) return 0;

    final left = readyAt.difference(clock.now());

    return left.isNegative ? 0 : (left.inMilliseconds / 1000).ceil();
  }

  void _onReadyAt() {
    _ticks?.cancel();
    if (_secondsLeft > 0) {
      _ticks = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsLeft == 0) timer.cancel();
        setState(() {});
      });
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final left = _secondsLeft;

    // The countdown digits differ in width, so a fixed minimum keeps the
    // button from twitching every second
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: _minWidth),
      child: D2Button(
        label: left > 0 ? formatClock(left) : t.game.hint,
        icon: D2Glyph.hint,
        kind: D2ButtonKind.hint,
        semanticLabel: left > 0 ? t.game.hintIn(time: formatClock(left)) : null,
        onPressed: left > 0
            ? null
            : () => showConfirmationDialog(
                context,
                message: t.game.showHelp,
                onOk: () =>
                    context.read<GameBloc>().add(const GameEventShowHelp()),
              ),
      ),
    );
  }
}
