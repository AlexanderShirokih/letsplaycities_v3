import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lets_play_cities/base/remote/bloc/local_multiplayer_bloc.dart';
import 'package:lets_play_cities/screens/common/common_widgets.dart';
import 'package:lets_play_cities/screens/common/drafting_screen.dart';

/// Waiting room for local multiplayer games
class LocalMultiplayerScreen extends StatelessWidget {
  /// Crates navigation route to show [LocalMultiplayerScreen]
  static Route createNavigationRoute(BuildContext context) => MaterialPageRoute(
        builder: (_) => DraftingScreen(), //LocalMultiplayerScreen(),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Мультиплеер'),
      ),
      body: BlocProvider(
        create: (_) => LocalMultiplayerBloc(),
        child: BlocConsumer<LocalMultiplayerBloc, LocalMultiplayerState>(
          builder: (context, state) {
            if (state is LocalMultiplayerWaitingForConnections) {
              return _WaitingForConnectionsView();
            } else {
              return _InitialUIView();
            }
          },
          listener: (context, state) {
            if (state is LocalMultiplayerJoiningState) {
              // TODO: Start [WaitingRoom] screen with local server address
            } else if (state is LocalMultiplayerNoWifiState) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Переподключитесь к Wi-Fi сети или попробуйте снова'),
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
  Widget build(BuildContext context) => Center(
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
                  width: 200.0,
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
                  width: 200.0,
                  child: createStyledMaterialButton(
                    context,
                    FaIcon(FontAwesomeIcons.wifi, size: 18.0),
                    'Присоединиться',
                    () => context
                        .read<LocalMultiplayerBloc>()
                        .add(LocalMultiplayerConnect()),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

// TODO: Implement
class _WaitingForConnectionsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
