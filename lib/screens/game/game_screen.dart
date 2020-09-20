import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lets_play_cities/base/game/bloc/game_bloc.dart';
import 'package:lets_play_cities/base/game/game_mode.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/l18n/localization_service.dart';
import 'package:lets_play_cities/screens/common/dialogs.dart';
import 'package:lets_play_cities/screens/common/error_handler_widget.dart';

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
    final l10n = context.repository<LocalizationService>();
    return Scaffold(
      body: WillPopScope(
        onWillPop: () async =>
            (await showConfirmationDialog(context,
                message: l10n.game['go_to_menu'])) ??
            false,
        child: Stack(
          children: [
            createBackground("bg_geo"),
            SizedBox.expand(
              child: BlocProvider(
                create: (_) => GameBloc(
                    prefs: prefs, gameMode: gameMode, localizations: l10n),
                child: Builder(
                  builder: (context) =>
                      BlocConsumer<GameBloc, GameLifecycleState>(
                    cubit: context.bloc<GameBloc>(),
                    builder: (context, state) {
                      if (state is GameState) {
                        return _buildGameStateLayout(state);
                      } else if (state is CheckingForUpdatesState) {
                        return LoadingView(
                            state.stage == CheckingForUpdatesStage.Updating
                                ? "Загрузка обновлений ${state.stagePercent}%"
                                : "Проверка обновлений словаря");
                      } else if (state is DataLoadingState) {
                        return LoadingView("Загрузка базы данных");
                      } else if (state is ErrorState) {
                        return ErrorHandlerView(
                          state.exception.toString(),
                          state.stackTrace.toString(),
                        );
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
