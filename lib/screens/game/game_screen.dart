import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lets_play_cities/base/dictionary.dart';
import 'package:lets_play_cities/base/game/bloc/game_bloc.dart';
import 'package:lets_play_cities/base/game/game_mode.dart';
import 'package:lets_play_cities/base/preferences.dart';

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
            child: BlocBuilder<GameBloc, GameLifecycleState>(
              cubit: GameBloc(
                prefs: context.repository<GamePreferences>(),
                gameMode: GameMode.PlayerVsAndroid,
                dictionaryUpdater: DictionaryUpdater(),
              ),
              builder: (context, state) {
                if (state is GameState) {
                  return _buildGameStateLayout(state);
                } else if (state is CheckingForUpdatesState) {
                  return _LoadingStateView(() {
                    return state.stage == CheckingForUpdatesStage.Updating
                        ? "Загрузка обновлений ${state.stagePercent}%"
                        : "Проверка обновлений словаря";
                  });
                } else if (state is DataLoadingState) {
                  return _LoadingStateView(() => "Загрузка базы данных");
                } else if (state is InitialState) {
                  return Placeholder();
                }
                throw ("Unknown state: $state");
              },
            ),
          )
        ],
      ),
    );
  }
}

Widget _buildGameStateLayout(GameState gameState) => RepositoryProvider(
      create: (BuildContext context) =>
          GameSessionRepository(gameState.gameFacade),
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
    );

typedef String FunctionStringCallback();

class _LoadingStateView extends StatelessWidget {
  final String _text;

  _LoadingStateView(FunctionStringCallback textBuilder)
      : assert(textBuilder != null),
        _text = textBuilder();

  @override
  Widget build(BuildContext context) => Center(
        child: Card(
          child: Container(
            padding: EdgeInsets.all(10.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 10.0),
                Text(_text, style: Theme.of(context).textTheme.headline6),
              ],
            ),
          ),
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
