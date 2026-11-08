import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/repos.dart';
import 'package:lets_play_cities/base/users.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/common/d2/d2.dart';
import 'package:lets_play_cities/utils/minutes_seconds.dart';

import 'combo_badge.dart';
import 'user_avatar.dart';

/// Score of both players with the letter of the move in the timer ring
/// between them. A [compact] panel, shown while the keyboard is open, has no
/// caption, a smaller ring, small avatars beside the names and no combo
/// badges.
///
/// Requires [GameSessionRepository] and [GameServiceEventsRepository].
class ScorePanel extends StatefulWidget {
  final bool compact;

  const ScorePanel({super.key, this.compact = false});

  @override
  State<ScorePanel> createState() => _ScorePanelState();
}

class _ScorePanelState extends State<ScorePanel> {
  static const _centerWidth = 128.0;

  late final GameSessionRepository _session;
  late final List<StreamSubscription<Object>> _subscriptions;

  User? _active;
  String _letter = '';
  late int _secondsLeft;

  // Subscribed once: a rebuild of the game layout must not reset the letter
  // and the active player until the next move.
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
    final left = _session.getUserByPosition(Position.left);
    final right = _session.getUserByPosition(Position.right);
    final compact = widget.compact;

    Widget card(User user) => Expanded(
      child: _PlayerCard(
        user,
        active: identical(user, _active),
        compact: compact,
      ),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(16, compact ? 4 : 8, 16, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [card(left), _buildLetter(context, compact), card(right)],
          ),
          // Kept mounted: a combo stream can be listened to only once.
          Visibility(
            visible: !compact,
            maintainState: true,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ComboBadgeWidget(left.comboSystem.eventStream),
                  ),
                  const SizedBox(width: _centerWidth),
                  Expanded(
                    child: ComboBadgeWidget(right.comboSystem.eventStream),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLetter(BuildContext context, bool compact) {
    final t = context.t;
    final c = D2Colors.of(context);
    final timeLimit = _session.timeLimit;
    final timed = timeLimit > 0;

    return SizedBox(
      width: _centerWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!compact) ...[
            Text(
              t.game.cityOnLetter,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: D2Text.body.copyWith(fontSize: 13, color: c.inkSoft),
            ),
            const SizedBox(height: 4),
          ],
          D2TimerRing(
            size: compact ? 64 : 104,
            progress: timed ? _secondsLeft / timeLimit : 0,
            child: D2LetterTile(
              _letter.isEmpty ? t.game.letterAny : _letter.toUpperCase(),
              size: compact ? 36 : 56,
              semanticLabel: _letter.isEmpty ? t.game.letterAnySemantics : null,
            ),
          ),
          if (timed) ...[
            SizedBox(height: compact ? 2 : 4),
            Semantics(
              label: t.game.secondsLeft(s: _secondsLeft),
              excludeSemantics: true,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  D2Icon(D2Glyph.timer, size: 16, color: c.ink),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      formatClock(_secondsLeft),
                      maxLines: 1,
                      style: D2Text.section.copyWith(color: c.ink),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Avatar, name and score of [user]; violet while it is the [user]'s move.
/// A [compact] card puts a small avatar beside the name and the score.
class _PlayerCard extends StatelessWidget {
  final User user;
  final bool active;
  final bool compact;

  const _PlayerCard(this.user, {required this.active, required this.compact});

  @override
  Widget build(BuildContext context) {
    final c = D2Colors.of(context);
    final onCard = active ? D2Colors.light.surface : c.ink;
    final avatarSize = compact ? 28.0 : 40.0;

    Widget avatar = Container(
      foregroundDecoration: active
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(avatarSize * 0.275),
              border: Border.all(color: D2Colors.light.surface, width: 2),
            )
          : null,
      child: buildD2AvatarForUser(user, size: avatarSize),
    );

    if (active && user is Player) {
      avatar = Semantics(
        container: true,
        label: context.t.game.yourTurn,
        child: avatar,
      );
    }

    final name = Text(
      user.name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: D2Text.body.copyWith(fontSize: 13, color: onCard),
    );

    final score = FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        '${user.score}',
        maxLines: 1,
        style: D2Text.score.copyWith(
          fontSize: compact ? 20 : 24,
          height: 1.1,
          color: onCard,
        ),
      ),
    );

    return Center(
      child: Container(
        width: 100,
        padding: compact
            ? const EdgeInsets.all(6)
            : const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: active ? c.violet : c.surface,
          borderRadius: BorderRadius.circular(compact ? 14 : 18),
          boxShadow: [
            BoxShadow(
              color: active ? c.shadow.withAlpha(56) : c.edge,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: compact
            ? Row(
                children: [
                  avatar,
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [name, score],
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  avatar,
                  const SizedBox(height: 4),
                  name,
                  const SizedBox(height: 4),
                  score,
                ],
              ),
      ),
    );
  }
}
