import 'dart:io';

import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:lets_play_cities/remote/server/routes/routes.dart';

import 'connection_transformer.dart';

/// Transport-level protocol connection
abstract class ServerConnection {
  /// Opens the server connection
  Future<void> start();

  /// Connects to the clients and returns message pipe to interact with them.
  /// Throws [RemoteException] if server is not started at this point or
  /// connection failed
  Stream<MessagePipe<String, String>> connect();

  /// Closes previously opened connection
  Future<void> close();

  /// Returns `true` if server has started and connected to the user
  bool get isOpened;
}

/// Server that uses WebSocket protocol to speak with client
class WebSocketServerConnection implements ServerConnection {
  HttpServer? _server;

  final RequestDispatcher _requestDispatcher;
  final AppConfig _appConfig;

  WebSocketServerConnection(
    this._appConfig,
    this._requestDispatcher,
  );

  @override
  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.anyIPv4, _appConfig.port);
  }

  @override
  Stream<MessagePipe<String, String>> connect() {
    if (_server == null) {
      throw RemoteException('Server is not started!');
    }
    return _server!
        .asyncMap(_requestDispatcher.dispatchRequest)
        .where((event) => event is MessagePipe<String, String>)
        .cast<MessagePipe<String, String>>();
  }

  @override
  bool get isOpened => _server != null;

  @override
  Future<void> close() async {
    if (_server != null) {
      await _server!.close(force: true);
      _server = null;
    }
  }
}
