import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/base/platform/network_manager.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/remote/account_manager.dart';
import 'package:lets_play_cities/remote/remote_host.dart';
import 'package:lets_play_cities/remote/server/server_game_controller.dart';
import 'package:lets_play_cities/utils/error_logger.dart';
import 'package:lets_play_cities/base/bloc/sequential_event_mapping.dart';

part 'local_multiplayer_event.dart';

part 'local_multiplayer_state.dart';

/// Bloc for handling local multiplayer connections
class LocalMultiplayerBloc
    extends Bloc<LocalMultiplayerEvent, LocalMultiplayerState>
    with SequentialEventMapping<LocalMultiplayerEvent, LocalMultiplayerState> {
  final ServerGameController _server;
  final ErrorLogger _errorLogger;

  /// The signed-in account names the player of a LAN game
  final AccountManager _accountManager;
  final GamePreferences _preferences;

  /// The name of a player who has neither an account nor a native name
  final String _defaultPlayerName;

  /// How long the name of the account may take: a LAN often has no internet
  final Duration _accountTimeout;

  LocalMultiplayerBloc({
    required this._server,
    required this._errorLogger,
    required this._accountManager,
    required this._preferences,
    required this._defaultPlayerName,
    this._accountTimeout = const Duration(seconds: 2),
  }) : super(LocalMultiplayerInitial()) {
    mapEventsSequentially(_mapEventToState);
    // Not sequential: a cancel must not wait for the creation it cancels
    on<LocalMultiplayerCancel>(_onCancel);
  }

  /// Set by [LocalMultiplayerCancel] while the server is starting
  var _createCancelled = false;

  @override
  Future<void> close() async {
    await _server.close();
    await super.close();
  }

  Stream<LocalMultiplayerState> _mapEventToState(
    LocalMultiplayerEvent event,
  ) async* {
    if (event is LocalMultiplayerCreate) {
      yield* _createConnection();
    } else if (event is LocalMultiplayerConnect) {
      yield* _connectToServer(event.selectedHost);
    } else if (event is LocalMultiplayerGameLeft) {
      // The host of this device ends with its game
      if (_server.isRunning) {
        await _server.close();
      }
      yield LocalMultiplayerInitial();
    }
  }

  Future<void> _onCancel(
    LocalMultiplayerCancel event,
    Emitter<LocalMultiplayerState> emit,
  ) async {
    if (state is! LocalMultiplayerStartingServer) return;

    _createCancelled = true;
    await _server.close();
    emit(LocalMultiplayerInitial());
  }

  Stream<LocalMultiplayerState> _createConnection() async* {
    _createCancelled = false;

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
        _errorLogger.error(e, s);
        await _server.close();
        yield LocalMultiplayerInitial();
        return;
      }

      if (_createCancelled) {
        // The server was set up after the cancel closed it
        await _server.close();
        return;
      }

      unawaited(
        _server.runGame().catchError((e, s) {
          _errorLogger.error(e, s);
        }),
      );

      final playerName = await _playerName();

      // A cancel meanwhile has closed the server
      if (_createCancelled) return;

      yield LocalMultiplayerStartGame(AppConfig.lan('localhost'), playerName);
    }
  }

  Stream<LocalMultiplayerState> _connectToServer(
    RemoteHost selectedHost,
  ) async* {
    final isNetworkReady = await NetworkManager.ensureWifiConnected();

    if (isNetworkReady) {
      yield LocalMultiplayerStartGame(
        AppConfig.lan(selectedHost.address),
        await _playerName(),
      );
    } else {
      yield LocalMultiplayerNoWifiState();
      yield LocalMultiplayerInitial();
    }
  }

  /// The name of the signed-in account, else the last native name, else the
  /// default name
  Future<String> _playerName() async {
    try {
      final account = await _accountManager.getLastSignedInAccount().timeout(
        _accountTimeout,
      );
      final name = account?.name.trim() ?? '';
      if (name.isNotEmpty) return name;
    } catch (e) {
      // No internet in the LAN, as is common, or no answer in time
      _errorLogger.log('The LAN game goes without the account name: $e');
    }

    final name = _preferences.lastNativeLogin.trim();

    return name.isEmpty ? _defaultPlayerName : name;
  }
}
