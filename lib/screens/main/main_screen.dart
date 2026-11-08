import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/base/achievements/achievements_service.dart';
import 'package:lets_play_cities/base/game/game_config.dart';
import 'package:lets_play_cities/base/game/game_mode.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/common/common_widgets.dart';
import 'package:lets_play_cities/screens/game/game_screen.dart';
import 'package:lets_play_cities/screens/main/cites/list/cities_list_screen.dart';
import 'package:lets_play_cities/screens/multiplayer/local_multiplayer_screen.dart';
import 'package:lets_play_cities/screens/online/game_master.dart';
import 'package:lets_play_cities/screens/settings/settings_screen.dart';

/// Describes the main screen
class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      createBackground(context),
      Column(
        children: [_createAppLogo(), _createNavigationButtonsGroup(context)],
      ),
      Positioned.fill(
        child: Container(
          alignment: Alignment.topRight,
          padding: EdgeInsets.only(top: 26.0, right: 16.0),
          child: SizedBox(
            width: 54.0,
            height: 54.0,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
              ),
              onPressed: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => SettingsScreen())),
              child: Icon(Icons.settings),
            ),
          ),
        ),
      ),
    ],
  );
}

Widget _createAppLogo() => Padding(
  padding: const EdgeInsets.fromLTRB(20.0, 64.0, 20.0, 20.0),
  child: Image.asset('assets/images/logo.png'),
);

Widget _createNavigationButtonsGroup(BuildContext context) => Expanded(
  child: Padding(
    padding: const EdgeInsets.only(bottom: 30.0),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 240.0,
          maxWidth: 260.0,
          minHeight: 230.0,
          maxHeight: 260.0,
        ),
        child: AnimatedMainButtons(),
      ),
    ),
  ),
);

class AnimatedMainButtons extends StatefulWidget {
  const AnimatedMainButtons({super.key});

  @override
  State<StatefulWidget> createState() => _AnimatedMainButtonsState();
}

class _AnimatedMainButtonsState extends State<AnimatedMainButtons>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _primaryButtonsOffset;
  late Animation<Offset> _secondaryButtonsOffset;

  void _setPrimaryButtonsVisibility(bool isVisible) {
    setState(() {
      if (!isVisible) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 360),
      vsync: this,
    );
    _primaryButtonsOffset = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1.5, 0.0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _secondaryButtonsOffset = Tween<Offset>(
      begin: const Offset(1.5, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // Primary buttons are fully shown: nothing to go back to.
        if (_controller.isDismissed) {
          SystemNavigator.pop();
        } else {
          _setPrimaryButtonsVisibility(true);
        }
      },
      child: Stack(
        children: [
          SlideTransition(
            position: _primaryButtonsOffset,
            child: _createPrimaryButtons(context),
          ),
          SlideTransition(
            position: _secondaryButtonsOffset,
            child: _createSecondaryButtons(context),
          ),
        ],
      ),
    );
  }

  Widget _createPrimaryButtons(BuildContext context) {
    final t = context.t;
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomMaterialButton(
          t.mainMenu.play,
          Icon(Icons.play_arrow),
          () => _setPrimaryButtonsVisibility(false),
        ),
        CustomMaterialButton(
          t.mainMenu.achievements,
          FaIcon(FontAwesomeIcons.medal),
          () => GetIt.instance
              .get<AchievementsService>()
              .showAchievementsScreen(),
        ),
        CustomMaterialButton(
          t.mainMenu.leaderboards,
          Icon(Icons.trending_up),
          () =>
              GetIt.instance.get<AchievementsService>().showLeaderboardScreen(),
        ),
        CustomMaterialButton(
          t.citiesList.title,
          Icon(Icons.apartment),
          () =>
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => CitiesListScreen())),
        ),
      ],
    );
  }

  Widget _createSecondaryButtons(BuildContext context) {
    final t = context.t;
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomMaterialButton(
          t.mainMenu.playerVsAndroid,
          Icon(Icons.android),
          () => _runGameScreen(context, GameMode.playerVsAndroid),
        ),
        CustomMaterialButton(
          t.mainMenu.playerVsPlayer,
          Icon(Icons.person),
          () => _runGameScreen(context, GameMode.playerVsPlayer),
        ),
        CustomMaterialButton(
          t.online.title,
          Icon(Icons.language),
          () => _runOnlineScreen(context),
        ),
        CustomMaterialButton(
          t.multiplayer.title,
          Icon(Icons.wifi),
          () => _runMultiplayerScreen(context),
        ),
      ],
    );
  }

  Future _runGameScreen(BuildContext context, GameMode gameMode) =>
      Navigator.push(
        context,
        GameScreen.createGameScreenRoute(GameConfig(gameMode: gameMode)),
      );

  Future _runOnlineScreen(BuildContext context) =>
      Navigator.push(context, OnlineGameMasterScreen.createNavigationRoute());

  Future _runMultiplayerScreen(BuildContext context) => Navigator.push(
    context,
    LocalMultiplayerScreen.createNavigationRoute(context),
  );
}
