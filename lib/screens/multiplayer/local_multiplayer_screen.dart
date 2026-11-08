import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/base/remote/bloc/local_multiplayer_bloc.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/remote/account_manager.dart';
import 'package:lets_play_cities/remote/api_repository_factory.dart';
import 'package:lets_play_cities/remote/remote_host.dart';
import 'package:lets_play_cities/remote/server/server_game_controller.dart';
import 'package:lets_play_cities/remote/server/user_lookup_repository.dart';
import 'package:lets_play_cities/screens/common/common_widgets.dart';
import 'package:lets_play_cities/screens/online/game_waiting_room_screen.dart';
import 'package:lets_play_cities/utils/error_logger.dart';

import 'searching_hosts_screen.dart';

/// Waiting room for local multiplayer games
class LocalMultiplayerScreen extends StatelessWidget {
  const LocalMultiplayerScreen({super.key});

  /// Crates navigation route to show [LocalMultiplayerScreen]
  static Route createNavigationRoute(BuildContext context) => MaterialPageRoute(
    builder: (_) => LocalMultiplayerScreen(),
    settings: RouteSettings(name: 'multiplayer'),
  );

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final getIt = GetIt.instance;
    return Scaffold(
      appBar: AppBar(title: Text(t.multiplayer.title)),
      body: BlocProvider(
        create: (_) => LocalMultiplayerBloc(
          server: getIt.get<ServerGameController>(),
          errorLogger: getIt.get<ErrorLogger>(),
          localConfig: getIt.get<AppConfig>(instanceName: 'local'),
          // Resolved when a game starts, as the 'local' factory reads the
          // unnamed AccountManager, which a LAN scope may override.
          createAccountManager: (config) =>
              getIt.get<AccountManager>(instanceName: 'local', param1: config),
        ),
        child: BlocConsumer<LocalMultiplayerBloc, LocalMultiplayerState>(
          builder: (context, state) {
            if (state is LocalMultiplayerStartingServer) {
              return LoadingView(t.multiplayer.startingServer);
            } else {
              return _InitialUIView();
            }
          },
          listener: (context, state) {
            if (state is LocalMultiplayerStartGame) {
              final getIt = GetIt.instance;
              pushLanGameScope(getIt, state);

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GameWaitingRoomScreenStandalone(),
                ),
              ).then((value) => getIt.popScope());
            } else if (state is LocalMultiplayerNoWifiState) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(t.multiplayer.reconnectWifi)),
              );
            } else if (state is LocalMultiplayerErrorState) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(t.multiplayer.error)));
            }
          },
        ),
      ),
    );
  }
}

/// Pushes the [getIt] scope of the LAN game that [game] starts. Inside it the
/// unnamed [AppConfig], the [AccountManager] and the [ApiRepositoryFactory]
/// target the LAN server; the factory keeps the picture URLs and the cache of
/// the one outside the scope.
@visibleForTesting
void pushLanGameScope(GetIt getIt, LocalMultiplayerStartGame game) {
  final apiRepositories = getIt.get<ApiRepositoryFactory>();
  getIt
    ..pushNewScope()
    ..registerSingleton<AppConfig>(game.configOverrides)
    ..registerSingleton<AccountManager>(game.accountManagerOverrides)
    ..registerSingleton<ApiRepositoryFactory>(
      apiRepositories.forServer(game.configOverrides),
    )
    ..registerSingleton<UserLookupRepository>(UserLookupRepositoryImpl());
}

/// Startup view with `connect` and `create connection` buttons
class _InitialUIView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Padding(
      padding: EdgeInsets.all(12.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t.multiplayer.sameWifiHint,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24.0),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 220.0,
                  child: createStyledMaterialButton(
                    context,
                    Icon(Icons.wifi_tethering, size: 20.0),
                    t.multiplayer.create,
                    () => context.read<LocalMultiplayerBloc>().add(
                      LocalMultiplayerCreate(),
                    ),
                  ),
                ),
                const SizedBox(height: 24.0),
                SizedBox(
                  width: 220.0,
                  child: createStyledMaterialButton(
                    context,
                    FaIcon(FontAwesomeIcons.wifi, size: 18.0),
                    t.multiplayer.join,
                    () =>
                        Navigator.push<RemoteHost?>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SearchingHostsScreen(),
                          ),
                        ).then((selectedHost) {
                          if (selectedHost != null && context.mounted) {
                            context.read<LocalMultiplayerBloc>().add(
                              LocalMultiplayerConnect(selectedHost),
                            );
                          }
                        }),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
