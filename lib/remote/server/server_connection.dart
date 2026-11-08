import 'dart:io';

import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:lets_play_cities/remote/server/routes/routes.dart';

/// Transport-level protocol connection
abstract class ServerConnection {
  /// Opens the server connection
  Future<void> start();

  /// The WebSockets of the clients that open the game route. Ends when the
  /// server closes. Throws [RemoteException] if the server is not started.
  Stream<WebSocket> connect();

  /// Closes previously opened connection. Does not close the WebSockets
  /// that [connect] gave.
  Future<void> close();

  /// Returns `true` if server has started and connected to the user
  bool get isOpened;
}

/// HTTP server of the LAN host that upgrades the game route to WebSocket
class WebSocketServerConnection implements ServerConnection {
  HttpServer? _server;

  final RequestDispatcher _requestDispatcher;
  final int _port;
  final Object _address;

  /// Listens on [port] (0 picks a free one) of [address], all IPv4
  /// interfaces by default
  WebSocketServerConnection(
    this._requestDispatcher, {
    this._port = AppConfig.lanPort,
    Object? address,
  }) : _address = address ?? InternetAddress.anyIPv4;

  /// The port the server listens on. Throws [RemoteException] if the server
  /// is not started.
  int get port => _started.port;

  HttpServer get _started {
    final server = _server;
    if (server == null) {
      throw RemoteException('Server is not started!');
    }

    return server;
  }

  @override
  Future<void> start() async {
    _server = await HttpServer.bind(_address, _port);
  }

  @override
  Stream<WebSocket> connect() => _started
      .asyncMap(_requestDispatcher.dispatchRequest)
      .where((result) => result is WebSocket)
      .cast<WebSocket>();

  @override
  bool get isOpened => _server != null;

  @override
  Future<void> close() async {
    final server = _server;
    _server = null;
    await server?.close(force: true);
  }
}
