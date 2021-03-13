import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/base/platform/network_manager.dart';
import 'package:lets_play_cities/remote/account_manager.dart';
import 'package:lets_play_cities/remote/remote_host.dart';
import 'package:lets_play_cities/remote/server/server_game_controller.dart';
import 'package:lets_play_cities/utils/error_logger.dart';
import 'package:pedantic/pedantic.dart';

part 'local_multiplayer_event.dart';

part 'local_multiplayer_state.dart';

/// Bloc for handling local multiplayer connections
class LocalMultiplayerBloc
    extends Bloc<LocalMultiplayerEvent, LocalMultiplayerState> {
  final ServerGameController _server;

  LocalMultiplayerBloc(
    this._server,
  ) : super(LocalMultiplayerInitial());

  @override
  Future<void> close() async {
    await _server.close();
    await super.close();
  }

  @override
  Stream<LocalMultiplayerState> mapEventToState(
      LocalMultiplayerEvent event) async* {
    if (event is LocalMultiplayerCreate) {
      yield* _createConnection();
    } else if (event is LocalMultiplayerConnect) {
      yield* _connectToServer(event.selectedHost);
    }
  }

  Stream<LocalMultiplayerState> _createConnection() async* {
    final isNetworkReady = await NetworkManager.ensureWifiConnected();

    if (isNetworkReady) {
      if (_server.isRunning) {
        await _server.close();
      }

      yield LocalMultiplayerStartingServer();

      // Wake up the server
      try {
        await _server.setUp();
      } catch (e, s) {
        yield LocalMultiplayerErrorState();
        GetIt.instance<ErrorLogger>().error(e, s);
        await _server.close();
        yield LocalMultiplayerInitial();
      }

      unawaited(_server.runGame().catchError((e, s) {
        GetIt.instance<ErrorLogger>().error(e, s);
      }));

      yield await _startGameForHost('localhost');
    }
  }

  Stream<LocalMultiplayerState> _connectToServer(
      RemoteHost selectedHost) async* {
    final isNetworkReady = await NetworkManager.ensureWifiConnected();

    if (isNetworkReady) {
      yield await _startGameForHost(selectedHost.address);
    } else {
      yield LocalMultiplayerNoWifiState();
      yield LocalMultiplayerInitial();
    }
  }

  Future<LocalMultiplayerStartGame> _startGameForHost(String host) async {
    final getIt = GetIt.instance;

    final appConfig =
        getIt.get<AppConfig>(instanceName: 'local').copy(host: host);

    final accMgr =
        getIt.get<AccountManager>(instanceName: 'local', param1: appConfig);

    return LocalMultiplayerStartGame(
      appConfig,
      accMgr,
    );
  }
}
