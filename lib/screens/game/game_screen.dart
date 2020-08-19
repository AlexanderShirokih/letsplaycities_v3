import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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

  Widget _createTopBar(BuildContext context) => Container(
        padding: EdgeInsets.fromLTRB(10.0, 40.0, 10.0, 24.0),
        color: Theme.of(context).accentColor,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _UserAvatar(
              userName: "Игрок",
              imageProvider: AssetImage("assets/images/player_big.png"),
              alignment: CrossAxisAlignment.start,
              isActive: true,
              onPressed: () {},
            ),
            _createActionButtons(context),
            _UserAvatar(
              userName: "Андроид",
              imageProvider: AssetImage("assets/images/android_big.png"),
              alignment: CrossAxisAlignment.end,
              isActive: false,
              onPressed: () {},
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

/// Creates circular user avatar with border around it.
class _UserAvatar extends StatelessWidget {
  final String userName;
  final CrossAxisAlignment alignment;
  final ImageProvider imageProvider;
  final bool isActive;
  final Function onPressed;

  const _UserAvatar({
    @required this.userName,
    @required this.imageProvider,
    @required this.alignment,
    this.isActive = false,
    this.onPressed,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: alignment,
        children: [
          Container(
            width: 70.0,
            height: 70.0,
            child: FlatButton(
              onPressed: onPressed,
              color: Colors.white,
              padding: EdgeInsets.zero,
              child: Image(image: imageProvider),
              shape: StadiumBorder(
                side: BorderSide(
                    color: isActive
                        ? Theme.of(context).primaryColorDark
                        : Colors.white,
                    width: 5.0),
              ),
            ),
          ),
          SizedBox(height: 4.0),
          Text(userName)
        ],
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
