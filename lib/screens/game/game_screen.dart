import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/base/game/bloc/game_bloc.dart';
import 'package:lets_play_cities/base/game/bloc/service_events_bloc.dart';
import 'package:lets_play_cities/base/game/game_config.dart';
import 'package:lets_play_cities/base/game/game_mode.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/base/repos.dart';
import 'package:lets_play_cities/screens/common/dialogs.dart';
import 'package:lets_play_cities/screens/common/error_handler_widget.dart';
import 'package:lets_play_cities/screens/common/sound_player.dart';
import 'package:lets_play_cities/screens/common/utils.dart';
import 'package:lets_play_cities/screens/game/first_time_onboarding_screen.dart';

import '../common/common_widgets.dart';
import '../game_results/game_results_screen.dart';
import 'cities_list.dart';
import 'city_checking_result_bar.dart';
import 'input_fields.dart';
import 'top_bar.dart';

/// Screen that shows all game-related interface
class GameScreen extends StatelessWidget {
  final GameConfig gameConfig;

  GameScreen(this.gameConfig);

  /// Creates new instance of [GameScreen] and wraps it with [MaterialPageRoute]
  static MaterialPageRoute createGameScreenRoute(GameConfig gameConfig) =>
      MaterialPageRoute(builder: (context) {
        final isFirstTime = GetIt.instance.get<GamePreferences>().isFirstLaunch;
        if (isFirstTime && gameConfig.gameMode.isLocal) {
          return buildWithLocalization(
            context,
            (l10n) => FirstTimeOnBoardingScreen(
              gameConfig: gameConfig,
              duration: const Duration(seconds: 4),
              strings: (l10n.firstTimeOnBoarding['messages'] as List<dynamic>)
                  .cast<String>(),
            ),
          );
        }
        return GameScreen(gameConfig);
      });

  @override
  Widget build(BuildContext context) {
    return buildWithLocalization(
      context,
      (l10n) => Scaffold(
        body: WillPopScope(
          onWillPop: () async =>
              (await showConfirmationDialog(context,
                  message: l10n.game['go_to_menu'])) ??
              false,
          child: Stack(
            children: [
              createBackground(context),
              SizedBox.expand(
                child: BlocProvider(
                  create: (_) => GameBloc(gameConfig: gameConfig),
                  child: Builder(
                    builder: (context) =>
                        BlocConsumer<GameBloc, GameLifecycleState>(
                      builder: (context, state) {
                        if (state is GameState) {
                          return _buildGameStateLayout(state);
                        } else if (state is CheckingForUpdatesState) {
                          return LoadingView(
                              state.stage == CheckingForUpdatesStage.Updating
                                  ? 'Загрузка обновлений ${state.stagePercent}%'
                                  : 'Проверка обновлений словаря');
                        } else if (state is DataLoadingState) {
                          return LoadingView('Загрузка базы данных');
                        } else if (state is ErrorState) {
                          return ErrorHandlerView(
                            state.exception.toString(),
                            state.stackTrace.toString(),
                          );
                        } else {
                          return Container(width: 0, height: 0);
                        }
                      },
                      listener: (context, state) {
                        if (state is GameResultsState) {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => GameResultsScreen(
                                state.gameResult,
                                state.gameConfig,
                              ),
                            ),
                          );
                        } else if (state is GameNotificationState) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(state.message),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildGameStateLayout(GameState gameState) => RepositoryProvider(
      create: (BuildContext context) => gameState.gameSessionRepository,
      child: BlocProvider<ServiceEventsBloc>.value(
        value: ServiceEventsBloc(),
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
            ),
            Builder(
              builder: (context) =>
                  context.watch<GamePreferences>().soundEnabled
                      ? SoundPlayer(
                          assetSoundPath: 'sound/click.mp3',
                          windowStream: context
                              .watch<GameSessionRepository>()
                              .createGameItemsRepository()
                              .getGameItems())
                      : SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
