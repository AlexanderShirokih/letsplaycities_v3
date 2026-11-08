import 'dart:async';

import 'package:lets_play_cities/remote/server/local_game_server.dart';
import 'package:lets_play_cities/remote/server/server_connection.dart';

/// Runs the LAN host of the device
abstract class ServerGameController {
  /// Returns `true` is server is running
  bool get isRunning;

  /// Runs the server
  Future<void> setUp();

  /// Serves the players until [close]
  Future<void> runGame();

  /// Ends the games, closes every socket and the server
  Future<void> close();
}

class ServerGameControllerImpl implements ServerGameController {
  final ServerConnection _connection;
  final LocalGameServer Function() _createHost;

  /// The games of the server started by the last [setUp]
  LocalGameServer? _host;

  ServerGameControllerImpl(this._connection, this._createHost);

  @override
  Future<void> setUp() async {
    await _host?.close();
    _host = _createHost();

    await _connection.start();
  }

  @override
  Future<void> runGame() async {
    final host = _host;
    if (host == null || !_connection.isOpened) return;

    await for (final socket in _connection.connect()) {
      host.serve(socket);
    }
  }

  @override
  Future<void> close() async {
    final host = _host;
    _host = null;

    // Closing the server does not close the upgraded WebSockets
    await host?.close();
    await _connection.close();
  }

  @override
  bool get isRunning => _connection.isOpened;
}
