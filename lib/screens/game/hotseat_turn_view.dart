import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lets_play_cities/base/game/game_item.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/i18n/time_format.dart';
import 'package:lets_play_cities/screens/common/d2/d2.dart';
import 'package:lets_play_cities/utils/minutes_seconds.dart';
import 'package:lets_play_cities/utils/string_utils.dart';

import 'cities_list.dart';

/// A player shown on [HotseatTurnView]. A player with a [controller] has an
/// editable name, [name] is the placeholder then.
class HotseatPlayer {
  final String name;
  final int score;
  final TextEditingController? controller;
  final String? fieldLabel;

  const HotseatPlayer({
    required this.name,
    this.score = 0,
    this.controller,
    this.fieldLabel,
  });
}

/// «Передайте телефон»: whose move is next, the score, the last city, the
/// letter and the paused timer of the move, and «Я готов».
class HotseatTurnView extends StatelessWidget {
  /// Index in [players] of the player who moves next
  final int activeIndex;
  final List<HotseatPlayer> players;
  final CityInfo? lastCity;

  /// Letter of the move, empty for any letter
  final String letter;

  /// Seconds per move, `0` when the moves are not timed
  final int timeLimit;
  final VoidCallback onBack;
  final VoidCallback onReady;

  const HotseatTurnView({
    super.key,
    required this.activeIndex,
    required this.players,
    required this.letter,
    required this.timeLimit,
    required this.onBack,
    required this.onReady,
    this.lastCity,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = D2Colors.of(context);
    final active = players[activeIndex];

    return ColoredBox(
      // Opaque for touches as well: nothing under the cover is reachable
      color: c.bg,
      child: SafeArea(
        child: CustomScrollView(
          // The moves feed under the cover is the primary scroll view
          primary: false,
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                children: [
                  D2ScreenHeader(onBack: onBack),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      child: Column(
                        children: [
                          _buildTitle(c, t, active),
                          const SizedBox(height: 14),
                          _buildPlayers(),
                          Expanded(child: _buildMove(context, c, t)),
                          D2Button(
                            label: t.hotseat.ready,
                            icon: D2Glyph.play,
                            size: D2ButtonSize.large,
                            expand: true,
                            onPressed: onReady,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(D2Colors c, Translations t, HotseatPlayer active) {
    final name = active.controller?.text.trim() ?? '';

    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            D2Icon(D2Glyph.phone, size: 18, color: c.inkSoft),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                t.hotseat.passPhone,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: D2Text.body.copyWith(fontSize: 15, color: c.inkSoft),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 70),
          child: Semantics(
            header: true,
            liveRegion: true,
            child: Text(
              t.hotseat.turnOf(name: name.isEmpty ? active.name : name),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: D2Text.display.copyWith(height: 1.15, color: c.ink),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayers() => Row(
    children: [
      for (var i = 0; i < players.length; i++) ...[
        if (i > 0) const SizedBox(width: 12),
        Expanded(
          child: _PlayerCard(
            players[i],
            number: i + 1,
            active: i == activeIndex,
          ),
        ),
      ],
    ],
  );

  Widget _buildMove(BuildContext context, D2Colors c, Translations t) {
    final city = lastCity;
    final timed = timeLimit > 0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 18),
        if (city != null) ...[_LastCity(city), const SizedBox(height: 18)],
        Text(
          t.game.cityOnLetter,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: D2Text.body.copyWith(fontSize: 13, color: c.inkSoft),
        ),
        const SizedBox(height: 4),
        D2TimerRing(
          size: 132,
          progress: timed ? 1 : 0,
          child: D2LetterTile(
            letter.isEmpty ? t.game.letterAny : letter.toUpperCase(),
            size: 72,
            semanticLabel: letter.isEmpty ? t.game.letterAnySemantics : null,
          ),
        ),
        if (timed) ...[
          const SizedBox(height: 4),
          Semantics(
            label:
                '${t.hotseat.timerPaused}, ${formatMinutesSeconds(t, timeLimit)}',
            excludeSemantics: true,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                D2Icon(D2Glyph.pause, size: 16, color: c.inkSoft),
                const SizedBox(width: 5),
                Text(
                  formatClock(timeLimit),
                  maxLines: 1,
                  style: D2Text.section.copyWith(color: c.inkSoft),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 18),
      ],
    );
  }
}

/// Number, name and score of a player; violet for the player who moves next
class _PlayerCard extends StatelessWidget {
  final HotseatPlayer player;
  final int number;
  final bool active;

  const _PlayerCard(this.player, {required this.number, required this.active});

  @override
  Widget build(BuildContext context) {
    final c = D2Colors.of(context);
    final onCard = active ? D2Colors.light.surface : c.ink;
    final soft = active ? D2Colors.light.edge : c.inkSoft;
    final nameStyle = D2Text.body.copyWith(fontSize: 15, color: onCard);
    final controller = player.controller;

    final Widget name = controller == null
        ? Text(
            player.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: nameStyle,
          )
        : TextField(
            controller: controller,
            inputFormatters: [LengthLimitingTextInputFormatter(10)],
            style: nameStyle,
            cursorColor: onCard,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              hintText: player.name,
              hintStyle: nameStyle.copyWith(color: soft),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          );

    return Semantics(
      selected: active,
      child: Container(
        constraints: const BoxConstraints(minHeight: 96),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        decoration: BoxDecoration(
          color: active ? c.violet : c.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: active ? c.shadow.withAlpha(56) : c.edge,
              offset: Offset(0, active ? 5 : 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 44,
              child: Row(
                children: [
                  _buildNumber(c),
                  const SizedBox(width: 8),
                  Expanded(
                    child: controller == null
                        ? name
                        : Semantics(label: player.fieldLabel, child: name),
                  ),
                  if (controller != null) ...[
                    const SizedBox(width: 8),
                    D2Icon(D2Glyph.edit, size: 16, color: soft),
                  ],
                ],
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${player.score}',
                maxLines: 1,
                style: D2Text.score.copyWith(
                  fontSize: 26,
                  height: 1,
                  color: onCard,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumber(D2Colors c) => ExcludeSemantics(
    child: Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? D2Colors.light.surface : c.yellow,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        '$number',
        style: D2Text.score.copyWith(
          fontSize: 14,
          height: 1,
          color: D2Colors.light.ink,
        ),
      ),
    ),
  );
}

/// The last accepted city with its flag and the letter of the move marked
class _LastCity extends StatelessWidget {
  final CityInfo city;

  const _LastCity(this.city);

  @override
  Widget build(BuildContext context) {
    final c = D2Colors.of(context);
    final name = city.city.toTitleCase();

    return Semantics(
      label: '${city.owner.name}: $name',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 14, 10),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: c.edge, offset: const Offset(0, 3))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CityFlag(city.countryCode),
            const SizedBox(width: 8),
            Flexible(
              child: Text.rich(
                cityNameSpans(name, c, fontSize: 19),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
