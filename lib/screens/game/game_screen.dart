import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/base/achievements/achievements_service.dart';
import 'package:lets_play_cities/base/dictionary/countrycode_overrides.dart';
import 'package:lets_play_cities/base/game/bloc/game_bloc.dart';
import 'package:lets_play_cities/base/game/game_config.dart';
import 'package:lets_play_cities/base/game/game_mode.dart';
import 'package:lets_play_cities/base/game/player/default_player_names.dart';
import 'package:lets_play_cities/base/game/turn_gate.dart';
import 'package:lets_play_cities/base/geo/route_data.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/base/repos.dart';
import 'package:lets_play_cities/base/stt/bloc/voice_recognition_bloc.dart';
import 'package:lets_play_cities/base/stt/voice_recognition_service.dart';
import 'package:lets_play_cities/i18n/slang_exclusion_messages.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/remote/dictionary_updater.dart';
import 'package:lets_play_cities/screens/common/dialogs.dart';
import 'package:lets_play_cities/screens/common/error_handler_widget.dart';
import 'package:lets_play_cities/screens/common/sound_player.dart';
import 'package:lets_play_cities/screens/game/first_time_onboarding_screen.dart';

import '../common/common_widgets.dart';
import '../game_results/game_results_screen.dart';
import '../game_results/route_results_screen.dart';
import 'game_layout.dart';
import 'hotseat_handoff.dart';
import 'route/route_game_layout.dart';

/// Screen that shows all game-related interface
class GameScreen extends StatelessWidget {
  final GameConfig gameConfig;

  const GameScreen(this.gameConfig, {super.key});

  /// Creates new instance of [GameScreen] and wraps it with [MaterialPageRoute]
  static MaterialPageRoute createGameScreenRoute(GameConfig gameConfig) =>
      MaterialPageRoute(
        builder: (context) {
          final isFirstTime = GetIt.instance
              .get<GamePreferences>()
              .isFirstLaunch;
          if (isFirstTime && gameConfig.gameMode.isLocal) {
            return FirstTimeOnBoardingScreen(gameConfig: gameConfig);
          }
          return GameScreen(gameConfig);
        },
      );

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    return Scaffold(
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          final navigator = Navigator.of(context);
          final shouldPop = await showConfirmationDialog(
            context,
            title: t.game.goToMenu,
            confirmLabel: t.game.exitConfirm,
            cancelLabel: t.game.stay,
          );
          if (shouldPop == true) navigator.pop();
        },
        child: Stack(
          children: [
            SizedBox.expand(
              child: BlocProvider(
                create: (_) => _createGameBloc(gameConfig, t),
                child: Builder(
                  builder: (context) =>
                      BlocConsumer<GameBloc, GameLifecycleState>(
                        builder: (context, state) {
                          if (state is GameState) {
                            return _buildGameStateLayout(
                              state,
                              gameConfig,
                              context.read<GameBloc>().turnGate,
                            );
                          } else if (state is CheckingForUpdatesState) {
                            return LoadingView(
                              state.stage == CheckingForUpdatesStage.updating
                                  ? t.game.downloadingUpdates(
                                      percent: state.stagePercent,
                                    )
                                  : t.game.checkingForUpdates,
                            );
                          } else if (state is DataLoadingState) {
                            return LoadingView(t.game.loadingDatabase);
                          } else if (state is ErrorState) {
                            return ErrorHandlerView(
                              state.exception.toString(),
                              state.stackTrace.toString(),
                            );
                          } else {
                            return SizedBox(width: 0, height: 0);
                          }
                        },
                        listener: (context, state) {
                          if (state is GameResultsState) {
                            _showResults(context, state);
                          } else if (state is GameNotificationState) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(switch (state.notification) {
                                  GameNotification.hintUnavailable =>
                                    t.game.hintUnavailable,
                                }),
                              ),
                            );
                          }
                        },
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Replaces the game route that owns [context] with [newRoute].
///
/// The game keeps running while a dialog is open over it, and
/// `pushReplacement` replaces the topmost route, so the dialogs above the
/// game route are closed first.
///
/// Does nothing when the game route is already leaving the navigator, e.g.
/// the player confirmed going to the menu and the game is still animating
/// out: the routes below it must stay.
@visibleForTesting
void replaceGameRoute(BuildContext context, Route<void> newRoute) {
  final navigator = Navigator.of(context);
  final gameRoute = ModalRoute.of(context);
  if (gameRoute != null && !gameRoute.isActive) return;
  if (gameRoute != null && !gameRoute.isCurrent) {
    navigator.popUntil((route) => route == gameRoute);
  }
  navigator.pushReplacement(newRoute);
}

/// Opens the results of a finished game: the route ones wait for the world
/// outline that their map needs.
Future<void> _showResults(BuildContext context, GameResultsState state) async {
  final result = state.gameResult;
  final world = result.route == null ? null : await RouteData.loadWorld();

  if (!context.mounted) return;

  replaceGameRoute(
    context,
    MaterialPageRoute(
      builder: (_) => world == null
          ? GameResultsScreen(result, state.gameConfig)
          : RouteResultsScreen(result, state.gameConfig, world: world),
    ),
  );
}

/// Called from the [BlocProvider.create] of [GameScreen]. The [Dio] goes to
/// the main server; in a LAN game it carries no token.
GameBloc _createGameBloc(GameConfig gameConfig, Translations t) {
  final getIt = GetIt.instance;
  final prefs = getIt.get<GamePreferences>();
  final hotseatNames = prefs.hotseatNames;

  // The names typed before the game, unless left empty
  String hotseatName(int index, String fallback) {
    final name = index < hotseatNames.length ? hotseatNames[index].trim() : '';

    return name.isEmpty ? fallback : name;
  }

  return GameBloc(
    gameConfig: gameConfig,
    prefs: prefs,
    exclusionMessages: SlangExclusionMessages(t),
    playerNames: DefaultPlayerNames(
      player: t.players.player,
      android: t.players.android,
      firstPlayer: hotseatName(0, t.players.firstPlayer),
      secondPlayer: hotseatName(1, t.players.secondPlayer),
    ),
    codeOverrides: getIt.get<CountryCodeOverrides>(),
    dictionaryUpdater: DictionaryUpdater(prefs, getIt.get<Dio>()),
    achievements: getIt.get<AchievementsService>(),
  );
}

/// The game covered by [HotseatHandoff] while [turnGate] holds a move.
Widget _buildGameStateLayout(
  GameState gameState,
  GameConfig gameConfig,
  TurnGate? turnGate,
) => MultiRepositoryProvider(
  providers: [
    RepositoryProvider<GameSessionRepository>(
      create: (_) => gameState.gameSessionRepository,
    ),
    RepositoryProvider<GameServiceEventsRepository>(
      create: (context) => context
          .read<GameSessionRepository>()
          .createGameServiceEventsRepository(),
    ),
  ],
  // One bloc per game, so auto-listening survives rebuilds of the input
  // field and recognition is cancelled when the game layout goes away.
  child: BlocProvider<VoiceRecognitionBloc>(
    create: (context) {
      final bloc = VoiceRecognitionBloc(
        gameState.gameSessionRepository.sendInputWord,
        GetIt.instance.get<VoiceRecognitionService>(),
      )..add(VoiceRecognitionInit());
      context.read<GameBloc>().onUserMoveBegins = () {
        if (!bloc.isClosed) bloc.add(VoiceRecognitionAutoBegin());
      };
      return bloc;
    },
    child: _withHandoff(
      turnGate,
      Column(
        children: [
          Expanded(
            child: Builder(
              builder: (context) {
                void onRegisterInputClear(VoidCallback clear) =>
                    context.read<GameBloc>().onUserInputAccepted = clear;

                return switch (gameConfig.variant) {
                  GameVariant.classic => GameLayout(
                    gameConfig,
                    onRegisterInputClear: onRegisterInputClear,
                  ),
                  GameVariant.route => RouteGameLayout(
                    gameConfig,
                    onRegisterInputClear: onRegisterInputClear,
                  ),
                };
              },
            ),
          ),
          Builder(
            builder: (context) => context.watch<GamePreferences>().soundEnabled
                ? SoundPlayer(
                    assetSoundPath: 'sound/click.mp3',
                    windowStream: context
                        .watch<GameSessionRepository>()
                        .createGameItemsRepository()
                        .getGameItems(),
                  )
                : SizedBox.shrink(),
          ),
        ],
      ),
    ),
  ),
);

Widget _withHandoff(TurnGate? turnGate, Widget game) =>
    turnGate == null ? game : HotseatHandoff(gate: turnGate, child: game);
