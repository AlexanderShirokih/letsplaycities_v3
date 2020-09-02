import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lets_play_cities/base/repos.dart';
import 'package:lets_play_cities/base/dictionary.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/base/game/game_mode.dart';
import 'package:lets_play_cities/base/game/bloc/game_bloc.dart';
import 'package:lets_play_cities/l18n/localization_service.dart';

import '../common/common_widgets.dart';

import 'top_bar.dart';
import 'input_fields.dart';
import 'cities_list.dart';
import 'city_checking_result_bar.dart';

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
                  localizations: context.repository<LocalizationService>()),
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
      create: (BuildContext context) => GameSessionRepository(
          gameState.dictionaryProxy, gameState.exclusionsService),
      child: _GameStarter(),
    );

typedef String FunctionStringCallback();

class _GameStarter extends StatefulWidget {
  @override
  _GameStarterState createState() => _GameStarterState();
}

class _GameStarterState extends State<_GameStarter> {
  @override
  Widget build(BuildContext context) => Column(
        children: [
          TopBar(),
          CitiesList(),
          Container(
            alignment: Alignment.bottomCenter,
            child: Column(
              children: [
                CityCheckingResultBar(),
                InputFieldsGroup(),
              ],
            ),
          )
        ],
      );

  @override
  void initState() {
    super.initState();

    _test();
  }

  _test() async {
    await Future.delayed(Duration(seconds: 2));
    context.repository<GameSessionRepository>().run();
  }
}

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
