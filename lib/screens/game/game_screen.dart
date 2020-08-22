import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lets_play_cities/base/repositories/game_session_repo.dart';
import 'package:lets_play_cities/screens/game/top_bar.dart';

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
            child: RepositoryProvider(
              create: (BuildContext context) => GameSessionRepository(),
              child: Column(
                children: [
                  TopBar(),
                  CitiesList(),
                  Container(
                    alignment: Alignment.bottomCenter,
                    child: _CityInputField(),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
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
