import 'package:flutter/material.dart';
import 'package:lets_play_cities/base/game/game_config.dart';
import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/game/game_mode.dart';
import 'package:lets_play_cities/base/game/game_result.dart';
import 'package:lets_play_cities/base/game/management.dart';
import 'package:lets_play_cities/base/game/rules/route_leg.dart';
import 'package:lets_play_cities/base/geo/world_outline.dart';
import 'package:lets_play_cities/base/platform/share.dart';
import 'package:lets_play_cities/base/users.dart';
import 'package:lets_play_cities/i18n/enum_labels.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/common/d2/d2.dart';
import 'package:lets_play_cities/screens/game/route/route_format.dart';
import 'package:lets_play_cities/screens/game/route/route_map.dart';
import 'package:lets_play_cities/screens/game/user_avatar.dart';
import 'package:lets_play_cities/screens/game_results/game_results_screen.dart';
import 'package:lets_play_cities/screens/game_results/route_share_card.dart';
import 'package:lets_play_cities/screens/game_results/share_image.dart';
import 'package:lets_play_cities/utils/string_utils.dart';

/// Shows when a Route game ends: kilometers of the players, the whole route
/// on the map and its totals.
class RouteResultsScreen extends StatefulWidget {
  final GameResult result;

  final GameConfig config;

  final WorldOutline world;

  /// Called by the button that shares the route; the route picture with the
  /// text is shared when not set
  final Future<void> Function(BuildContext context)? onShare;

  const RouteResultsScreen(
    this.result,
    this.config, {
    super.key,
    required this.world,
    this.onShare,
  });

  @override
  State<RouteResultsScreen> createState() => _RouteResultsScreenState();
}

class _RouteResultsScreenState extends State<RouteResultsScreen> {
  /// Set while the picture is rendered and shared: more taps are ignored
  bool _sharing = false;

  GameResult get result => widget.result;

  GameConfig get config => widget.config;

  WorldOutline get world => widget.world;

  RouteState get _route => result.route!;

  List<RouteLeg> get _accepted =>
      _route.legs.where((leg) => !leg.skipped).toList();

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final accepted = _accepted;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 36, 16, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(context, t),
                    const SizedBox(height: 16),
                    _buildKmCard(context, t),
                    const SizedBox(height: 14),
                    _buildMap(context, t, accepted),
                    const SizedBox(height: 14),
                    _buildMetrics(context, t, accepted),
                    const SizedBox(height: 16),
                    const Spacer(),
                    _buildButtons(context, t, accepted.isNotEmpty),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Translations t) {
    final c = D2Colors.of(context);
    final (glyph, tile) = switch (result.matchResult) {
      MatchResult.win => (D2Glyph.trophy, c.yellow),
      MatchResult.lose => (D2Glyph.surrender, c.yellow),
      MatchResult.draw => (D2Glyph.equal, c.sky),
    };

    return Column(
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: tile,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: c.shadow.withAlpha(56),
                offset: const Offset(0, 5),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: D2Icon(
            glyph,
            size: 38,
            color: D2Colors.light.ink,
            strokeWidth: 2.25,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          result.matchResult.label(t),
          textAlign: TextAlign.center,
          style: D2Text.display.copyWith(fontSize: 30, color: c.ink),
        ),
        // A finished route needs no reason, only an early end does
        if (result.finishType != MoveFinishType.routeCompleted) ...[
          const SizedBox(height: 6),
          Text(
            result.finishType.finishDescription(t, result.finishRequester.name),
            textAlign: TextAlign.center,
            style: D2Text.bodyRegular.copyWith(color: c.inkSoft),
          ),
        ],
      ],
    );
  }

  Widget _buildKmCard(BuildContext context, Translations t) {
    final c = D2Colors.of(context);
    final opponent = result.opponent;

    return D2Card(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        children: [
          _KmRow(
            result.owner,
            config.gameMode == GameMode.playerVsAndroid ? t.route.you : null,
            _route.km[result.owner] ?? 0,
          ),
          if (opponent != null) ...[
            const SizedBox(height: 6),
            Container(height: 2, color: c.bg),
            const SizedBox(height: 6),
            _KmRow(opponent, null, _route.km[opponent] ?? 0),
          ],
        ],
      ),
    );
  }

  Widget _buildMap(
    BuildContext context,
    Translations t,
    List<RouteLeg> accepted,
  ) {
    final c = D2Colors.of(context);
    final last = accepted.isEmpty ? null : accepted.last.city;

    return Container(
      height: 162,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: c.edge, offset: const Offset(0, 3))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: RouteMap(
          world: world,
          legs: _route.legs,
          colorOf: (user) => routeColorOf(user, c),
          highlight: _longestLeg()?.$1,
          semanticLabel: last == null
              ? null
              : t.route.mapLabel(n: accepted.length, city: last.toTitleCase()),
        ),
      ),
    );
  }

  Widget _buildMetrics(
    BuildContext context,
    Translations t,
    List<RouteLeg> accepted,
  ) {
    final c = D2Colors.of(context);
    final countries = {
      for (final leg in accepted)
        if (leg.countryCode != 0) leg.countryCode,
    };
    final longest = _longestLeg();
    final valueStyle = D2Text.title.copyWith(fontSize: 20, color: c.ink);

    return D2Card(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              flex: 10,
              child: _Metric(
                label: t.route.countries,
                value: Text('${countries.length}', style: valueStyle),
              ),
            ),
            Container(width: 2, color: c.bg),
            // 1 : 1.7 : 1, as in D2-RouteResults
            Expanded(
              flex: 17,
              child: _Metric(
                label: t.route.longestLeg,
                semanticValue: longest?.$2,
                value: Text.rich(
                  TextSpan(
                    style: valueStyle,
                    children: [
                      TextSpan(text: formatKm(longest?.$1.km ?? 0)),
                      TextSpan(
                        text: '$kmSpace${t.route.km}',
                        style: D2Text.small.copyWith(
                          fontSize: 13,
                          color: c.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(width: 2, color: c.bg),
            Expanded(
              flex: 10,
              child: _Metric(
                label: t.route.cities,
                value: Text('${accepted.length}', style: valueStyle),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The accepted leg with the most kilometers and its «from — to» label,
  /// `null` if there is none. The «from» is the previous city on the map.
  (RouteLeg, String)? _longestLeg() {
    final legs = _route.legs;
    var best = -1;

    for (var i = 0; i < legs.length; i++) {
      if (!legs[i].skipped && (best < 0 || legs[i].km > legs[best].km)) {
        best = i;
      }
    }

    if (best < 0) return null;

    // A city without coordinates is not on the map, so it is no start of a
    // flight
    String? from;
    for (var i = best - 1; i >= 0; i--) {
      if (!legs[i].skipped && legs[i].point != null) {
        from = legs[i].city;
        break;
      }
    }

    final to = legs[best].city!.toTitleCase();

    return (legs[best], from == null ? to : '${from.toTitleCase()} — $to');
  }

  /// Shares the route once at a time and tells the user when it fails
  Future<void> _onSharePressed() async {
    if (_sharing) return;

    _sharing = true;
    final messenger = ScaffoldMessenger.of(context);
    final failed = context.t.route.shareFailed;

    try {
      await (widget.onShare ?? _share)(context);
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(failed)));
    } finally {
      _sharing = false;
    }
  }

  /// Renders the route picture and shares it with the text
  Future<void> _share(BuildContext context) async {
    final text = routeShareText(context.t, _route, result.owner);

    final path = await renderShareImage(
      context,
      RouteShareCard(
        world: world,
        route: _route,
        owner: result.owner,
        opponent: result.opponent,
        matchResult: result.matchResult,
      ),
      size: const Size.square(routeShareCardSize),
      fileName: 'route_share.png',
    );

    await Share.image(path, text);
  }

  Widget _buildButtons(BuildContext context, Translations t, bool canShare) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        D2Button(
          label: t.gameResults.playAgain,
          icon: D2Glyph.replay,
          size: D2ButtonSize.large,
          expand: true,
          onPressed: () =>
              Navigator.pushReplacement(context, replayRoute(config)),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: D2Button(
                label: t.gameResults.toMenu,
                icon: D2Glyph.exit,
                kind: D2ButtonKind.secondary,
                expand: true,
                onPressed: () =>
                    Navigator.popUntil(context, (route) => route.isFirst),
              ),
            ),
            if (canShare) ...[
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: D2Button(
                  label: t.route.share,
                  icon: D2Glyph.share,
                  kind: D2ButtonKind.secondary,
                  expand: true,
                  onPressed: _onSharePressed,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Avatar, name and kilometers of one user
class _KmRow extends StatelessWidget {
  final User user;

  /// Replaces the name of [user]
  final String? nameOverride;

  final int km;

  const _KmRow(this.user, this.nameOverride, this.km);

  @override
  Widget build(BuildContext context) {
    final c = D2Colors.of(context);
    final color = routeKmColorOf(user, c);

    return SizedBox(
      height: 36,
      child: Row(
        children: [
          buildD2AvatarForUser(user, size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              nameOverride ?? user.name,
              overflow: TextOverflow.ellipsis,
              style: D2Text.body.copyWith(fontSize: 15, color: c.ink),
            ),
          ),
          Text.rich(
            TextSpan(
              style: D2Text.score.copyWith(fontSize: 18, color: color),
              children: [
                TextSpan(text: formatKm(km)),
                TextSpan(
                  text: '$kmSpace${context.t.route.km}',
                  style: D2Text.small.copyWith(
                    fontSize: 13,
                    color: user.position == Position.left ? color : c.ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A value with its label under it
class _Metric extends StatelessWidget {
  final String label;
  final Widget value;

  /// Said after [label] by screen readers
  final String? semanticValue;

  const _Metric({required this.label, required this.value, this.semanticValue});

  @override
  Widget build(BuildContext context) {
    final c = D2Colors.of(context);
    final spoken = label.replaceAll('\n', ' ');

    return Semantics(
      label: semanticValue == null ? null : '$spoken: $semanticValue',
      excludeSemantics: semanticValue != null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 12, 4, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            value,
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              style: D2Text.small.copyWith(
                fontWeight: FontWeight.w400,
                color: c.inkSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
