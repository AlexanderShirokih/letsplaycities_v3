import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/game/game_item.dart';
import 'package:lets_play_cities/base/game/rules/route_rules.dart';
import 'package:lets_play_cities/base/game/turn_gate.dart';
import 'package:lets_play_cities/base/repos.dart';
import 'package:lets_play_cities/utils/string_utils.dart';

import 'hotseat_turn_view.dart';

/// Covers the game while [gate] holds a move, so the phone can be passed to
/// the next player.
///
/// Every touch is taken by the cover: the game does not listen to its menu
/// actions while the gate is closed. The first move of the game is let go at
/// once, the players confirmed it before the game.
///
/// Requires [GameSessionRepository].
class HotseatHandoff extends StatefulWidget {
  final TurnGate gate;
  final Widget child;

  const HotseatHandoff({super.key, required this.gate, required this.child});

  /// `true` while the cover hides the game that [context] belongs to. The
  /// game widgets that open something over the game close it then.
  static bool isCovering(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_Covering>()?.covering ??
      false;

  @override
  State<HotseatHandoff> createState() => _HotseatHandoffState();
}

class _HotseatHandoffState extends State<HotseatHandoff> {
  late final GameSessionRepository _session;
  late final StreamSubscription<List<GameItem>> _items;

  @override
  void initState() {
    super.initState();
    _session = context.read<GameSessionRepository>();

    // The gate may close before the last city reaches the items.
    _items = _session.gameItemsRepository.getItemsList().listen((_) {
      if (_shown) setState(() {});
    });
    widget.gate.waiting.addListener(_onWaitingChanged);
    _handleWaiting();
  }

  @override
  void dispose() {
    widget.gate.waiting.removeListener(_onWaitingChanged);
    _items.cancel();
    super.dispose();
  }

  /// No city is accepted before the first move
  bool get _shown =>
      widget.gate.waiting.value != null && _session.lastAcceptedWord.isNotEmpty;

  void _onWaitingChanged() {
    _handleWaiting();
    setState(() {});
  }

  /// Lets the first move go and clears the way for the cover of the others.
  /// Runs after the notification of the gate.
  void _handleWaiting() {
    final next = widget.gate.waiting.value;
    if (next == null) return;

    scheduleMicrotask(() {
      if (!mounted || widget.gate.waiting.value != next) return;

      if (_session.lastAcceptedWord.isEmpty) {
        widget.gate.release();
      } else {
        _closeRoutesAbove();
      }
    });
  }

  /// A menu opened just before the move ended would stay above the cover
  void _closeRoutesAbove() {
    final route = ModalRoute.of(context);
    if (route != null && route.isActive && !route.isCurrent) {
      Navigator.of(context).popUntil((r) => r == route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shown = _shown;

    return Stack(
      fit: StackFit.passthrough,
      children: [
        ExcludeFocus(
          excluding: shown,
          child: ExcludeSemantics(
            excluding: shown,
            child: _Covering(covering: shown, child: widget.child),
          ),
        ),
        if (shown) Positioned.fill(child: _buildCover(context)),
      ],
    );
  }

  Widget _buildCover(BuildContext context) {
    final next = widget.gate.waiting.value!;
    final left = _session.getUserByPosition(Position.left);
    final right = _session.getUserByPosition(Position.right);
    final lastCity = _session.gameItemsRepository.items
        .whereType<CityInfo>()
        .lastOrNull;
    final letter = findLastSuitableChar(_session.lastAcceptedWord);
    final route = _session.routeState;

    return HotseatTurnView(
      activeIndex: identical(next, left) ? 0 : 1,
      players: [
        for (final user in [left, right])
          HotseatPlayer(
            name: user.name,
            score: route == null ? user.score : route.km[user] ?? 0,
          ),
      ],
      routeMove: route == null
          ? null
          : min(route.movesOf(next) + 1, RouteRules.movesPerPlayer),
      lastCity: lastCity,
      letter: letter,
      timeLimit: _session.timeLimit,
      onBack: () => Navigator.maybePop(context),
      onReady: widget.gate.release,
    );
  }
}

class _Covering extends InheritedWidget {
  final bool covering;

  const _Covering({required this.covering, required super.child});

  @override
  bool updateShouldNotify(_Covering old) => old.covering != covering;
}
