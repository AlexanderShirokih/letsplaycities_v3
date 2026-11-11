import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lets_play_cities/base/game/game_item.dart';
import 'package:lets_play_cities/base/game/rules/route_rules.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/i18n/time_format.dart';
import 'package:lets_play_cities/screens/common/design/design.dart';
import 'package:lets_play_cities/utils/minutes_seconds.dart';
import 'package:lets_play_cities/utils/string_utils.dart';

import 'cities_list.dart';
import 'route/route_format.dart';

/// A player shown on [HotseatTurnView]. A player with a [controller] has an
/// editable name, [name] is the placeholder then.
class HotseatPlayer {
  final String name;

  /// Points, or km in a Route game
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
/// letter and the paused timer of the move, and «Я готов». In a Route game
/// the score is in km and the number of the move is shown.
class HotseatTurnView extends StatelessWidget {
  /// Index in [players] of the player who moves next
  final int activeIndex;
  final List<HotseatPlayer> players;
  final CityInfo? lastCity;

  /// Letter of the move, empty for any letter
  final String letter;

  /// Seconds per move, `0` when the moves are not timed
  final int timeLimit;

  /// Number of the next move in a Route game, from 1; `null` in the classic
  /// game
  final int? routeMove;

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
    this.routeMove,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = AppColors.of(context);
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
                  AppScreenHeader(onBack: onBack),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      child: Column(
                        children: [
                          _buildTitle(c, t, active),
                          const SizedBox(height: 14),
                          _buildPlayers(),
                          if (routeMove case final move?) ...[
                            const SizedBox(height: 12),
                            Text(
                              t.route.move(
                                n: move,
                                total: RouteRules.movesPerPlayer,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.section.copyWith(
                                fontSize: 13,
                                color: c.ink,
                              ),
                            ),
                          ],
                          Expanded(child: _buildMove(context, c, t)),
                          AppButton(
                            label: t.hotseat.ready,
                            icon: AppGlyph.play,
                            size: AppButtonSize.large,
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

  Widget _buildTitle(AppColors c, Translations t, HotseatPlayer active) {
    final name = active.controller?.text.trim() ?? '';

    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(AppGlyph.phone, size: 18, color: c.inkSoft),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                t.hotseat.passPhone,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.body.copyWith(fontSize: 15, color: c.inkSoft),
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
              style: AppText.display.copyWith(height: 1.15, color: c.ink),
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
            km: routeMove != null,
          ),
        ),
      ],
    ],
  );

  Widget _buildMove(BuildContext context, AppColors c, Translations t) {
    final city = lastCity;
    final timed = timeLimit > 0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 18),
        if (city != null) ...[_LastCity(city), const SizedBox(height: 18)],
        // The caption is only read out: the tile speaks for itself
        Semantics(
          label: t.game.cityOnLetter,
          child: AppTimerRing(
            size: 132,
            progress: timed ? 1 : 0,
            child: AppLetterTile(
              letter.isEmpty ? t.game.letterAny : letter.toUpperCase(),
              size: 72,
              semanticLabel: letter.isEmpty ? t.game.letterAnySemantics : null,
            ),
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
                AppIcon(AppGlyph.pause, size: 16, color: c.inkSoft),
                const SizedBox(width: 5),
                Text(
                  formatClock(timeLimit),
                  maxLines: 1,
                  style: AppText.section.copyWith(color: c.inkSoft),
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
class _PlayerCard extends StatefulWidget {
  final HotseatPlayer player;
  final int number;
  final bool active;

  /// The score is in km
  final bool km;

  const _PlayerCard(
    this.player, {
    required this.number,
    required this.active,
    required this.km,
  });

  @override
  State<_PlayerCard> createState() => _PlayerCardState();
}

class _PlayerCardState extends State<_PlayerCard> {
  final _nameFocus = FocusNode();

  HotseatPlayer get player => widget.player;
  int get number => widget.number;
  bool get active => widget.active;
  bool get km => widget.km;

  @override
  void dispose() {
    _nameFocus.dispose();
    super.dispose();
  }

  /// The pencil starts the editing with the whole name selected
  void _editName() {
    final controller = player.controller!;

    _nameFocus.requestFocus();
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final onCard = active ? AppColors.light.surface : c.ink;
    final soft = active ? AppColors.light.edge : c.inkSoft;
    final nameStyle = AppText.body.copyWith(fontSize: 15, color: onCard);
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
            focusNode: _nameFocus,
            inputFormatters: [LengthLimitingTextInputFormatter(10)],
            style: nameStyle,
            cursorColor: onCard,
            // «Готово» closes the keyboard, and so does a tap outside
            textInputAction: TextInputAction.done,
            onTapOutside: (_) => _nameFocus.unfocus(),
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
                  if (controller != null)
                    ExcludeSemantics(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _editName,
                        child: SizedBox(
                          width: 36,
                          height: 44,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: AppIcon(AppGlyph.edit, size: 16, color: soft),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                km
                    ? '${formatKm(player.score)}$kmSpace${context.t.route.km}'
                    : '${player.score}',
                maxLines: 1,
                style: AppText.score.copyWith(
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

  Widget _buildNumber(AppColors c) => ExcludeSemantics(
    child: Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? AppColors.light.surface : c.yellow,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        '$number',
        style: AppText.score.copyWith(
          fontSize: 14,
          height: 1,
          color: AppColors.light.ink,
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
    final c = AppColors.of(context);
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
