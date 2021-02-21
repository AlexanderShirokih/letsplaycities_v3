import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/base/remote/bloc/local_multiplayer_bloc.dart';
import 'package:lets_play_cities/remote/account_manager.dart';
import 'package:lets_play_cities/remote/remote_host.dart';
import 'package:lets_play_cities/remote/server/user_lookup_repository.dart';
import 'package:lets_play_cities/screens/common/common_widgets.dart';
import 'package:lets_play_cities/screens/online/game_waiting_room_screen.dart';

import 'searching_hosts_screen.dart';

/// Waiting room for local multiplayer games
class LocalMultiplayerScreen extends StatelessWidget {
  /// Crates navigation route to show [LocalMultiplayerScreen]
  static Route createNavigationRoute(BuildContext context) => MaterialPageRoute(
        builder: (_) => LocalMultiplayerScreen(),
        settings: RouteSettings(name: 'multiplayer'),
      );

  @override
  Widget build(BuildContext context) {
    final getIt = GetIt.instance;
    return Scaffold(
      appBar: AppBar(
        title: Text('Мультиплеер'),
      ),
      body: BlocProvider(
        create: (_) => LocalMultiplayerBloc(getIt.get()),
        child: BlocConsumer<LocalMultiplayerBloc, LocalMultiplayerState>(
          builder: (context, state) {
            if (state is LocalMultiplayerStartingServer) {
              return LoadingView('Запуск сервера...');
            } else {
              return _InitialUIView();
            }
          },
          listener: (context, state) {
            if (state is LocalMultiplayerStartGame) {
              final getIt = GetIt.instance
                ..pushNewScope()
                ..registerSingleton<AppConfig>(state.configOverrides)
                ..registerSingleton<AccountManager>(
                    state.accountManagerOverrides)
                ..registerSingleton<UserLookupRepository>(
                    UserLookupRepositoryImpl());

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GameWaitingRoomScreenStandalone(),
                ),
              ).then(
                (value) => getIt.popScope(),
              );
            } else if (state is LocalMultiplayerNoWifiState) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Переподключитесь к Wi-Fi сети или попробуйте снова'),
                ),
              );
            } else if (state is LocalMultiplayerErrorState) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Произошла какая-то ошибка :('),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

/// Startup view with `connect` and `create connection` buttons
class _InitialUIView extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.all(12.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Для создания соединения вы должны находиться в одной Wi-Fi сети с вашим оппонентом',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headline6,
              ),
              const SizedBox(height: 24.0),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 220.0,
                    child: createStyledMaterialButton(
                      context,
                      Icon(Icons.wifi_tethering, size: 20.0),
                      'Создать',
                      () => context
                          .read<LocalMultiplayerBloc>()
                          .add(LocalMultiplayerCreate()),
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  Container(
                    width: 220.0,
                    child: createStyledMaterialButton(
                      context,
                      FaIcon(FontAwesomeIcons.wifi, size: 18.0),
                      'Присоединиться',
                      () => Navigator.push<RemoteHost?>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SearchingHostsScreen(),
                        ),
                      ).then((selectedHost) {
                        if (selectedHost != null) {
                          context
                              .read<LocalMultiplayerBloc>()
                              .add(LocalMultiplayerConnect(selectedHost));
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
