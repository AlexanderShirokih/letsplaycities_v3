import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/game/rules/route_rules.dart';
import 'package:lets_play_cities/base/repos.dart';
import 'package:lets_play_cities/base/users.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/common/d2/d2.dart';

import '../user_avatar.dart';
import 'route_format.dart';
import 'route_progress.dart';

/// Km of both players with the letter of the move in the timer ring between
/// them, and the progress of the current player below.
///
/// Requires [GameSessionRepository] and [GameServiceEventsRepository].
class RouteScorePanel extends StatefulWidget {
  final RouteState state;

  const RouteScorePanel(this.state, {super.key});

  @override
  State<RouteScorePanel> createState() => _RouteScorePanelState();
}

class _RouteScorePanelState extends State<RouteScorePanel> {
  static const _centerWidth = 80.0;

  late final GameSessionRepository _session;
  late final List<StreamSubscription<Object>> _subscriptions;

  User? _active;
  String _letter = '';
  late int _secondsLeft;

  // Subscribed once: a rebuild of the layout must not reset the letter and
  // the active player until the next move.
  @override
  void initState() {
    super.initState();
    _session = context.read<GameSessionRepository>();
    _secondsLeft = _session.timeLimit;

    final events = context.read<GameServiceEventsRepository>();
    _subscriptions = [
      events.getUserSwitches().listen(
        (event) => setState(() {
          _active = event.nextUser;
          _secondsLeft = _session.timeLimit;
        }),
      ),
      events.getFirstChars().listen((c) => setState(() => _letter = c)),
      events.getTimerTicks().listen((s) => setState(() => _secondsLeft = s)),
    ];
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final left = _session.getUserByPosition(Position.left);
    final right = _session.getUserByPosition(Position.right);
    final active = _active ?? left;
    const total = RouteRules.movesPerPlayer;
    final move = (state.movesOf(active) + 1).clamp(1, total);

    Widget card(User user, {required bool end}) => Expanded(
      child: _KmCard(
        user,
        km: state.km[user] ?? 0,
        active: identical(user, active),
        end: end,
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              card(left, end: false),
              const SizedBox(width: 8),
              _buildLetter(context),
              const SizedBox(width: 8),
              card(right, end: true),
            ],
          ),
          const SizedBox(height: 10),
          RouteProgress(move: move, total: total),
        ],
      ),
    );
  }

  Widget _buildLetter(BuildContext context) {
    final t = context.t;
    final timeLimit = _session.timeLimit;
    final timed = timeLimit > 0;

    Widget ring = D2TimerRing(
      size: 76,
      progress: timed ? _secondsLeft / timeLimit : 0,
      child: D2LetterTile(
        _letter.isEmpty ? t.game.letterAny : _letter.toUpperCase(),
        size: 40,
        semanticLabel: _letter.isEmpty ? t.game.letterAnySemantics : null,
      ),
    );

    if (timed) {
      ring = Semantics(
        value: t.game.secondsLeft(s: _secondsLeft),
        child: ring,
      );
    }

    // The caption is only read out: the tile speaks for itself on screen
    return SizedBox(
      width: _centerWidth,
      child: Center(
        child: Semantics(label: t.route.letterCaption, child: ring),
      ),
    );
  }
}

/// Avatar, name and km of [user]; violet while it is the [user]'s move
class _KmCard extends StatelessWidget {
  static const _avatarSize = 26.0;

  final User user;
  final int km;
  final bool active;

  /// Aligned to the end, for the card on the right
  final bool end;

  const _KmCard(
    this.user, {
    required this.km,
    required this.active,
    required this.end,
  });

  @override
  Widget build(BuildContext context) {
    final c = D2Colors.of(context);
    final onCard = active ? D2Colors.light.surface : c.ink;

    Widget avatar = Container(
      foregroundDecoration: active
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: D2Colors.light.surface, width: 2),
            )
          : null,
      child: buildD2AvatarForUser(user, size: _avatarSize),
    );

    if (active && user is Player) {
      avatar = Semantics(
        container: true,
        label: context.t.game.yourTurn,
        child: avatar,
      );
    }

    final name = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        avatar,
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            user.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: D2Text.body.copyWith(fontSize: 13, color: onCard),
          ),
        ),
      ],
    );

    final value = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: end ? Alignment.centerRight : Alignment.centerLeft,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: formatKm(km),
              style: D2Text.score.copyWith(
                fontSize: 16,
                height: 1.1,
                color: active ? onCard : c.letter,
              ),
            ),
            TextSpan(
              text: '$kmSpace${context.t.route.km}',
              style: D2Text.body.copyWith(fontSize: 13, color: onCard),
            ),
          ],
        ),
        maxLines: 1,
      ),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: BoxDecoration(
        color: active ? c.violet : c.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: active ? c.shadow.withAlpha(56) : c.edge,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: end
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [name, const SizedBox(height: 4), value],
      ),
    );
  }
}
