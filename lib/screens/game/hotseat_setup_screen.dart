import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lets_play_cities/base/game/game_config.dart';
import 'package:lets_play_cities/base/game/game_mode.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';

import 'game_screen.dart';
import 'hotseat_turn_view.dart';

/// Names of the two players on one phone, before their game starts.
///
/// «Я готов» saves the names and replaces this screen with the game route
/// made by [gameRoute].
///
/// Requires [GamePreferences].
class HotseatSetupScreen extends StatefulWidget {
  final Route<dynamic> Function(GameConfig config) gameRoute;

  const HotseatSetupScreen({
    super.key,
    this.gameRoute = GameScreen.createGameScreenRoute,
  });

  @override
  State<HotseatSetupScreen> createState() => _HotseatSetupScreenState();
}

class _HotseatSetupScreenState extends State<HotseatSetupScreen> {
  late final GamePreferences _prefs;
  late final List<TextEditingController> _names;

  var _starting = false;

  @override
  void initState() {
    super.initState();
    _prefs = context.read<GamePreferences>();

    final saved = _prefs.hotseatNames;
    _names = [
      for (var i = 0; i < 2; i++)
        TextEditingController(text: i < saved.length ? saved[i] : '')
          ..addListener(() => setState(() {})),
    ];
  }

  @override
  void dispose() {
    for (final controller in _names) {
      controller.dispose();
    }
    super.dispose();
  }

  void _start() {
    if (_starting) return;
    _starting = true;

    _prefs.hotseatNames = [for (final name in _names) name.text.trim()];
    Navigator.of(context).pushReplacement(
      widget.gameRoute(
        GameConfig(
          gameMode: GameMode.playerVsPlayer,
          variant: _prefs.gameVariant,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    return Scaffold(
      body: HotseatTurnView(
        activeIndex: 0,
        players: [
          HotseatPlayer(
            name: t.hotseat.player1,
            controller: _names[0],
            fieldLabel: t.hotseat.nameLabel1,
          ),
          HotseatPlayer(
            name: t.hotseat.player2,
            controller: _names[1],
            fieldLabel: t.hotseat.nameLabel2,
          ),
        ],
        letter: '',
        timeLimit: _prefs.timeLimit,
        onBack: () => Navigator.maybePop(context),
        onReady: _start,
      ),
    );
  }
}
