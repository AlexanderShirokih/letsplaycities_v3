import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/base/game/game_config.dart';
import 'package:lets_play_cities/base/game/rules/route_leg.dart';
import 'package:lets_play_cities/base/geo/world_outline.dart';
import 'package:lets_play_cities/base/repos.dart';
import 'package:lets_play_cities/base/repositories/cities/country_repository.dart';
import 'package:lets_play_cities/base/stt/bloc/voice_recognition_bloc.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/common/design/design.dart';
import 'package:lets_play_cities/utils/string_utils.dart';

import '../game_layout.dart';
import '../input_fields.dart';
import '../top_bar.dart';
import 'route_feed.dart';
import 'route_format.dart';
import 'route_map.dart';
import 'route_score_panel.dart';

/// Top row, km, the progress, the route map, the last moves and the input
/// panel of a Route game.
///
/// On a short screen the map shrinks first, then the feed loses its oldest
/// rows; the input panel keeps its height.
///
/// Requires [GameSessionRepository], [GameServiceEventsRepository] and
/// [VoiceRecognitionBloc].
class RouteGameLayout extends StatefulWidget {
  /// Height of the map card with its padding
  static const mapHeight = 156.0;

  /// A map lower than this is not shown
  static const minMapHeight = 64.0;

  final GameConfig gameConfig;

  /// See [InputFieldsGroup.onRegisterInputClear]
  final ValueSetter<VoidCallback> onRegisterInputClear;

  const RouteGameLayout(
    this.gameConfig, {
    super.key,
    required this.onRegisterInputClear,
  });

  @override
  State<RouteGameLayout> createState() => _RouteGameLayoutState();
}

class _RouteGameLayoutState extends State<RouteGameLayout> {
  static const _mapTop = 8.0;

  late final GameSessionRepository _session;

  // The getter makes a new stream on every call
  late final Stream<RouteState> _states;

  Map<int, String> _countryNames = const {};

  @override
  void initState() {
    super.initState();
    _session = context.read<GameSessionRepository>();
    _states = _session.routeStates!;
    _loadCountryNames();
  }

  Future<void> _loadCountryNames() async {
    final getIt = GetIt.instance;
    if (!getIt.isRegistered<CountryRepository>()) return;

    try {
      final list = await getIt.get<CountryRepository>().getCountryList();
      if (!mounted) return;

      setState(() {
        _countryNames = {for (final c in list) c.countryCode: c.name};
      });
    } catch (_) {
      // The feed reads the country as unknown
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SafeArea(bottom: false, child: TopBar(widget.gameConfig)),
      Expanded(
        child: StreamBuilder<RouteState>(
          stream: _states,
          initialData: _session.routeState,
          builder: (context, snapshot) =>
              _buildBody(context, snapshot.requireData),
        ),
      ),
    ],
  );

  Widget _buildBody(BuildContext context, RouteState state) => LayoutBuilder(
    builder: (context, box) => Column(
      children: [
        // Only a screen too short for the input and its result scales the
        // score down
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: max(
              box.maxHeight -
                  GameLayout.minInputHeight -
                  GameLayout.resultHeight,
              0,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(width: box.maxWidth, child: RouteScorePanel(state)),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) => Column(
              children: [
                Expanded(child: _buildRoute(context, state)),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: box.maxHeight),
                  child: InputFieldsGroup(
                    onRegisterInputClear: widget.onRegisterInputClear,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  /// The map over the feed: the feed takes its height first and the map
  /// gets the rest, up to [RouteGameLayout.mapHeight]
  Widget _buildRoute(BuildContext context, RouteState state) {
    final world = _session.world;
    final legs = state.legs;

    final feed = legs.isEmpty
        ? null
        : Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: RouteFeed(legs: legs, countryNames: _countryNames),
          );

    return LayoutBuilder(
      builder: (context, box) => Column(
        children: [
          if (world != null)
            Flexible(
              child: LayoutBuilder(
                builder: (context, mapBox) =>
                    mapBox.maxHeight < RouteGameLayout.minMapHeight
                    ? const SizedBox(width: double.infinity)
                    : _buildMap(context, world, legs, mapBox.maxHeight),
              ),
            ),
          if (feed != null)
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: box.maxHeight),
              child: ClipRect(
                child: SingleChildScrollView(
                  primary: false,
                  physics: const NeverScrollableScrollPhysics(),
                  child: feed,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMap(
    BuildContext context,
    WorldOutline world,
    List<RouteLeg> legs,
    double maxHeight,
  ) {
    final c = AppColors.of(context);
    final cities = legs.where((leg) => !leg.skipped).toList(growable: false);
    final last = cities.lastOrNull?.city;

    return Container(
      height: min(maxHeight - _mapTop, RouteGameLayout.mapHeight),
      margin: const EdgeInsets.fromLTRB(16, _mapTop, 16, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: c.edge, offset: const Offset(0, 3))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: RouteMap(
          world: world,
          legs: legs,
          colorOf: (user) => routeColorOf(user, c),
          semanticLabel: last == null
              ? null
              : context.t.route.mapLabel(
                  n: cities.length,
                  city: last.toTitleCase(),
                ),
        ),
      ),
    );
  }
}
