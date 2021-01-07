import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lets_play_cities/base/game/game_config.dart';
import 'package:lets_play_cities/base/game/game_mode.dart';
import 'package:lets_play_cities/base/game/game_result.dart';
import 'package:lets_play_cities/base/game/management.dart';
import 'package:lets_play_cities/l18n/localization_service.dart';
import 'package:lets_play_cities/platform/share.dart';
import 'package:lets_play_cities/screens/common/utils.dart';
import 'package:lets_play_cities/screens/game/game_screen.dart';
import 'package:lets_play_cities/screens/game/user_avatar.dart';
import 'package:lets_play_cities/themes/theme.dart' as theme;
import 'package:lets_play_cities/utils/string_utils.dart';

/// Shows when the game ends
class GameResultsScreen extends StatelessWidget {
  static final _kContainerHeight = 480.0;
  static final _kAvatarRadius = 52.0;

  final GameResult _gameResult;

  final GameConfig _gameConfig;

  const GameResultsScreen(this._gameResult, this._gameConfig);

  @override
  Widget build(BuildContext context) => Scaffold(
        body: buildWithLocalization(
          context,
          (l10n) => Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  context.watch<theme.Theme>().backgroundImage,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 5.0,
                    sigmaY: 5.0,
                  ),
                  child: Container(
                    color: Colors.black.withOpacity(0.0),
                  ),
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
                          Theme.of(context).primaryColor
                        ]),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        (l10n.gameResults['match_result']
                                as List<dynamic>)[_gameResult.matchResult.index]
                            .toString(),
                        style: Theme.of(context)
                            .textTheme
                            .headline3
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        _getDescriptionText(l10n),
                        style: Theme.of(context).textTheme.subtitle1,
                      ),
                      _gameResult.hasScore
                          ? _buildScoreContainer(context, l10n)
                          : const SizedBox(height: 48.0),
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
                                color: Colors.black.withOpacity(0.5),
                                spreadRadius: 2)
                          ],
                        ),
                        child: buildAvatarForUser(_gameResult.owner, 50.0),
                      )
                    ],
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
                          onPressed: () => Share.text(l10n
                              .gameResults['share_score']
                              .toString()
                              .format([_gameResult.owner.score.toString()])),
                          child: Icon(Icons.share),
                        ),
                      const SizedBox(height: 24.0),
                      FloatingActionButton(
                        heroTag: 'replay',
                        onPressed: () => _gameConfig.gameMode.isLocal()
                            ? Navigator.pushReplacement(context,
                                GameScreen.createGameScreenRoute(_gameConfig))
                            : Navigator.pop(context),
                        child: Icon(Icons.replay),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildScoreContainer(BuildContext context, LocalizationService l10n) =>
      Container(
        margin: EdgeInsets.symmetric(vertical: 18.0),
        height: 96.0,
        decoration: BoxDecoration(
            color: Theme.of(context).primaryColorDark,
            boxShadow: [
              BoxShadow(
                blurRadius: 6,
                color: Colors.black.withOpacity(0.4),
                spreadRadius: 0.5,
              )
            ]),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Text(
                l10n.gameResults['score'].toString().toUpperCase(),
                style: Theme.of(context)
                    .accentTextTheme
                    .headline5
                    .copyWith(fontWeight: FontWeight.w400),
              ),
              Text(
                _gameResult.owner.score.toString(),
                style: Theme.of(context)
                    .accentTextTheme
                    .headline5
                    .copyWith(fontWeight: FontWeight.w900),
              )
            ],
          ),
        ),
      );

  String _getDescriptionText(LocalizationService l10n) =>
      l10n.gameResults[_getLocalizationKey()]
          .toString()
          .format([_gameResult.finishRequester.name]);

  String _getLocalizationKey() {
    switch (_gameResult.finishType) {
      case MoveFinishType.Timeout:
        return 'desc_timeout';
      case MoveFinishType.Disconnected:
        return 'desc_disconnected';
      case MoveFinishType.Surrender:
        return 'desc_surrender';
      default:
    }
    throw ('Unknown move finish type!');
  }
}
