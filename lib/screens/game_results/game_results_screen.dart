import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lets_play_cities/l18n/localization_service.dart';
import 'package:lets_play_cities/screens/common/utils.dart';
import 'package:lets_play_cities/screens/game/user_avatar.dart';
import 'package:lets_play_cities/themes/theme.dart' as theme;
import 'package:lets_play_cities/base/game/game_result.dart';

/// Shows when the game ends
class GameResultsScreen extends StatelessWidget {
  static final _kContainerOffset = 280.0;
  static final _kAvatarRadius = 52.0;

  final GameResult _gameResult;

  const GameResultsScreen(this._gameResult);

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                context.repository<theme.Theme>().backgroundImage,
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
            Positioned.fromRelativeRect(
              rect: RelativeRect.fromLTRB(0.0, _kContainerOffset, 0.0, 0.0),
              child: withLocalization(
                context,
                (l10n) => Container(
                  padding: EdgeInsets.only(top: _kAvatarRadius + 18.0),
                  width: double.maxFinite,
                  height: 340.0,
                  color: Theme.of(context).primaryColor,
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
                        "${_gameResult.finishType}",
                        style: Theme.of(context).textTheme.subtitle1,
                      ),
                      _gameResult.hasScore
                          ? _buildScoreContainer(context, l10n)
                          : const SizedBox(height: 48.0),
                      IconTheme(
                        data: Theme.of(context).accentIconTheme,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _createSupportButton(context, Icons.share,
                                l10n.gameResults['share'], 0, () {}),
                            _createSupportButton(context, Icons.menu,
                                l10n.gameResults['menu'], 20, () {}),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fromRelativeRect(
              rect: RelativeRect.fromLTRB(
                  0.0, _kContainerOffset - _kAvatarRadius, 0.0, 0.0),
              child: Column(
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
                    child: CircleAvatar(
                      child:
                          buildUserAvatar(_gameResult.owner.playerData.picture),
                      radius: _kAvatarRadius,
                    ),
                  )
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0, bottom: 20.0),
                child: FloatingActionButton(
                  onPressed: () {},
                  child: Icon(Icons.replay),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _createSupportButton(BuildContext context, IconData icon, String name,
          double additionalWidth, Function onPressed) =>
      RaisedButton(
        padding: EdgeInsets.symmetric(
            vertical: 8.0, horizontal: 8.0 + additionalWidth),
        color: Theme.of(context).accentColor,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.0)),
        onPressed: onPressed,
        child: IconTheme(
          data: Theme.of(context).accentIconTheme,
          child: Row(
            children: [
              Icon(icon),
              const SizedBox(width: 4.0),
              Text(
                name.toUpperCase(),
                style: Theme.of(context).accentTextTheme.subtitle1,
              )
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
                  blurRadius: 12,
                  color: Colors.black.withOpacity(0.8),
                  spreadRadius: -24)
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
}
