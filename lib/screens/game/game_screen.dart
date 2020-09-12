import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lets_play_cities/base/game/bloc/game_bloc.dart';
import 'package:lets_play_cities/base/game/game_mode.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/l18n/localization_service.dart';

import '../common/common_widgets.dart';
import 'cities_list.dart';
import 'city_checking_result_bar.dart';
import 'game_results_screen.dart';
import 'input_fields.dart';
import 'top_bar.dart';

class GameScreen extends StatelessWidget {
  final GameMode gameMode;

  GameScreen(this.gameMode);

  @override
  Widget build(BuildContext context) {
    final prefs = context.repository<GamePreferences>();
    return Scaffold(
      body: Stack(
        children: [
          createBackground("bg_geo"),
          SizedBox.expand(
            child: BlocProvider(
              create: (_) => GameBloc(
                  prefs: prefs,
                  gameMode: gameMode,
                  localizations: context.repository<LocalizationService>()),
              child: Builder(
                builder: (context) =>
                    BlocConsumer<GameBloc, GameLifecycleState>(
                  cubit: context.bloc<GameBloc>(),
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
                    } else
                      // [InitialState] || [GameResultsState]
                      return Container(width: 0, height: 0);
                  },
                  listener: (context, state) {
                    if (state is GameResultsState)
                      Navigator.of(context).pushReplacement(MaterialPageRoute(
                          builder: (_) => GameResultsScreen()));
                  },
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

Widget _buildGameStateLayout(GameState gameState) => RepositoryProvider(
      create: (BuildContext context) => gameState.gameSessionRepository,
      child: Column(
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
