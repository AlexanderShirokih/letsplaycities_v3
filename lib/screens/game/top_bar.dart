import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/repositories/game_session_repo.dart';

import 'user_avatar.dart';

class TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.fromLTRB(10.0, 40.0, 10.0, 24.0),
        color: Theme.of(context).accentColor,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            UserAvatar.ofUser(
              onPressed: () {},
              user: context
                  .repository<GameSessionRepository>()
                  .getUserByPosition(Position.LEFT),
            ),
            _createActionButtons(context),
            UserAvatar.ofUser(
              onPressed: () {},
              user: context
                  .repository<GameSessionRepository>()
                  .getUserByPosition(Position.RIGHT),
            ),
          ],
        ),
      );

  Widget _createActionButtons(BuildContext context) => Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _createRoundBorderedButtons(context, FontAwesomeIcons.bars),
                _createRoundBorderedButtons(context, FontAwesomeIcons.flag),
                _createRoundBorderedButtons(
                    context, FontAwesomeIcons.lightbulb),
              ],
            ),
            SizedBox(width: 0.0, height: 16.0),
            Text(
              "23:15",
              style: Theme.of(context).textTheme.headline6,
            ),
          ],
        ),
      );

  Widget _createRoundBorderedButtons(
          BuildContext context, IconData faIconData) =>
      Container(
        width: 56.0,
        height: 56.0,
        child: RaisedButton(
          color: Theme.of(context).accentColor,
          padding: const EdgeInsets.all(10.0),
          onPressed: () {},
          child: FaIcon(faIconData, color: Colors.white),
          shape:
              StadiumBorder(side: BorderSide(color: Colors.white, width: 3.0)),
        ),
      );
}
