import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lets_play_cities/base/auth.dart';
import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/data/app_version.dart';
import 'package:lets_play_cities/base/dictionary.dart';
import 'package:lets_play_cities/base/game/game_facade.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/base/users.dart';
import 'package:lets_play_cities/screens/game/user_avatar.dart';

import '../common/common_widgets.dart';
import 'cities_list.dart';

class GameScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          createBackground("bg_geo"),
          SizedBox.expand(
            child: Column(
              children: [
                _createTopBar(context),
                CitiesList(),
                Container(
                  alignment: Alignment.bottomCenter,
                  child: _CityInputField(),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _createTopBar(BuildContext context) {
    var exclusions = ExclusionsService();
    var dictionary = DictionaryService();
    var gamePreferences = GamePreferences();
    var gameFacade = new GameFacade(exclusions, dictionary, gamePreferences);

    return Container(
      padding: EdgeInsets.fromLTRB(10.0, 40.0, 10.0, 24.0),
      color: Theme.of(context).accentColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          UserAvatar.ofUser(
            onPressed: () {},
            user: Player(
              gameFacade,
              PlayerData(
                accountInfo: ClientAccountInfo.forName("Игрок"),
                versionInfo: VersionInfo.stub(),
              ),
            ),
          ),
          _createActionButtons(context),
          UserAvatar.ofUser(
            user: Android(gameFacade, "Андроид"),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

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

/// Input field for entering cities
class _CityInputField extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.all(8.0),
        color: Colors.white,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MaterialIconButton(Icons.keyboard_voice),
            _createKeyboardField(context),
            const MaterialIconButton(Icons.add_circle_outline),
          ],
        ),
      );

  Widget _createKeyboardField(BuildContext context) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: TextField(
            cursorColor: Theme.of(context).primaryColor,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(border: InputBorder.none),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp("^[А-я-.' ]+\$"),
              )
            ],
          ),
        ),
      );
}
