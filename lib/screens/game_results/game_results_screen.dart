import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/base/ads/advertising_helper.dart';
import 'package:lets_play_cities/base/game/game_config.dart';
import 'package:lets_play_cities/base/game/game_mode.dart';
import 'package:lets_play_cities/base/game/game_result.dart';
import 'package:lets_play_cities/base/platform/share.dart';
import 'package:lets_play_cities/i18n/enum_labels.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/remote/account.dart';
import 'package:lets_play_cities/remote/remote_player.dart';
import 'package:lets_play_cities/screens/game/game_screen.dart';
import 'package:lets_play_cities/screens/game/user_avatar.dart';
import 'package:lets_play_cities/screens/online/profile.dart';

/// Shows when the game ends
class GameResultsScreen extends StatefulWidget {
  final GameResult _gameResult;

  final GameConfig _gameConfig;

  const GameResultsScreen(this._gameResult, this._gameConfig, {super.key});

  @override
  State<GameResultsScreen> createState() => _GameResultsScreenState();
}

class _GameResultsScreenState extends State<GameResultsScreen> {
  static final _kContainerHeight = 480.0;
  static final _kAvatarRadius = 52.0;

  GameResult get _gameResult => widget._gameResult;

  GameConfig get _gameConfig => widget._gameConfig;

  @override
  void initState() {
    super.initState();
    // Once per screen: build() runs again on every theme, locale or layout
    // change. Ad errors are not shown to the user.
    GetIt.instance.get<AdManager>().showInterstitial().ignore();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Container(color: Colors.black.withValues(alpha: 0.0)),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: EdgeInsets.only(top: _kAvatarRadius + 18.0),
              width: double.maxFinite,
              height: _kContainerHeight,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).primaryColorLight,
                    Theme.of(context).primaryColor,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _gameResult.matchResult.label(t),
                    style: Theme.of(context).textTheme.displaySmall!
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    _gameResult.finishType.finishDescription(
                      t,
                      _gameResult.finishRequester.name,
                    ),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  _gameResult.hasScore
                      ? _buildScoreContainer(context, t)
                      : const SizedBox(height: 48.0),
                  ..._buildRemoteOpponentsNavigator(context),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0.0,
            right: 0.0,
            bottom: _kContainerHeight - _kAvatarRadius,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          offset: const Offset(0.0, 4.0),
                          blurRadius: 8,
                          color: Colors.black.withValues(alpha: 0.5),
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: buildAvatarForUser(_gameResult.owner, 50.0),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0, bottom: 24.0),
              child: FloatingActionButton(
                heroTag: 'back',
                onPressed: () => Navigator.pop(context),
                child: Icon(Icons.arrow_back),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0, bottom: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_gameResult.hasScore && _gameResult.owner.score > 0)
                    FloatingActionButton(
                      heroTag: 'share',
                      onPressed: () => Share.text(
                        t.gameResults.shareScore(
                          score: _gameResult.owner.score,
                        ),
                      ),
                      child: Icon(Icons.share),
                    ),
                  const SizedBox(height: 24.0),
                  FloatingActionButton(
                    heroTag: 'replay',
                    onPressed: () => _gameConfig.gameMode.isLocal
                        ? Navigator.pushReplacement(
                            context,
                            GameScreen.createGameScreenRoute(_gameConfig),
                          )
                        : (_gameConfig.gameMode == GameMode.multiplayer
                              ? Navigator.popUntil(
                                  context,
                                  (route) =>
                                      route.settings.name == 'multiplayer',
                                )
                              : Navigator.pop(context)),
                    child: Icon(Icons.replay),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreContainer(BuildContext context, Translations t) =>
      Container(
        margin: EdgeInsets.symmetric(vertical: 18.0),
        height: 96.0,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColorDark,
          boxShadow: [
            BoxShadow(
              blurRadius: 6,
              color: Colors.black.withValues(alpha: 0.4),
              spreadRadius: 0.5,
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Text(
                t.gameResults.score.toUpperCase(),
                style: Theme.of(context).primaryTextTheme.headlineSmall!
                    .copyWith(fontWeight: FontWeight.w400),
              ),
              Text(
                _gameResult.owner.score.toString(),
                style: Theme.of(context).primaryTextTheme.headlineSmall!
                    .copyWith(fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      );

  Iterable<Widget> _buildRemoteOpponentsNavigator(BuildContext context) sync* {
    if (_gameConfig.gameMode != GameMode.network) return;

    var opponents = _getRemoteOpponents();

    if (opponents.isEmpty) return;
    yield Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12.0, 8.0, 0.0, 8.0),
          child: Text(
            context.t.gameResults.youPlayedWith,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
      ],
    );

    yield Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0),
        child: ListView(
          children: opponents
              .map(
                (opp) => Card(
                  child: ListTile(
                    contentPadding: EdgeInsets.all(10.0),
                    leading: buildAvatarForUser(opp, 45.0),
                    title: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        FaIcon(
                          FontAwesomeIcons.upRightFromSquare,
                          color: Theme.of(context).textTheme.bodySmall!.color,
                          size: 14.0,
                        ),
                        const SizedBox(width: 6.0),
                        Text(opp.accountInfo.name, overflow: TextOverflow.fade),
                      ],
                    ),
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OnlineProfileViewStandalone(
                          (opp.accountInfo as AdvancedAccountInfo).profileInfo,
                        ),
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Iterable<RemotePlayer> _getRemoteOpponents() {
    return _gameConfig.usersListOverride?.all
            .where((user) => user != _gameResult.owner && user is RemotePlayer)
            .cast<RemotePlayer>() ??
        <RemotePlayer>[];
  }
}
