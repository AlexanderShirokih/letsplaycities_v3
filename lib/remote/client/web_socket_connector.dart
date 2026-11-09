import 'dart:async';
import 'dart:io';

import 'package:lets_play_cities/remote/client/api_exception.dart';
import 'package:lets_play_cities/remote/client/base_socket_connector.dart';
import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:rxdart/rxdart.dart';
import 'package:web_socket_channel/io.dart';

/// Opens a WebSocket connection to [uri].
typedef WebSocketFactory = Future<WebSocket> Function(String uri);

/// WebSocket implementation of socket commutator
class WebSocketConnector implements AbstractSocketConnector {
  final String _uri;
  final WebSocketFactory? _openSocket;
  final Duration _connectTimeout;

  /// How often the socket that [_defaultOpen] opens pings the server: a
  /// network that dropped the connection silently ends it with a close
  final Duration _pingInterval;

  /// Sent with the upgrade request, e.g. `Authorization`
  final Map<String, String> _headers;

  IOWebSocketChannel? _channel;
  Future? _workStreamDone;

  WebSocketConnector(
    this._uri, {
    this._openSocket,
    this._connectTimeout = const Duration(seconds: 10),
    this._pingInterval = const Duration(seconds: 20),
    this._headers = const {},
  });

  StreamController<SocketMessage>? _streamController;

  Future<WebSocket> _defaultOpen(String uri) async =>
      await WebSocket.connect(uri, headers: _headers)
        ..pingInterval = _pingInterval;

  @override
  void connect() {
    if (_channel != null) {
      throw RemoteException(
        'Cannot create new connection while previous does not stopped',
      );
    }

    final controller = _controller();
    final opening = (_openSocket ?? _defaultOpen)(_uri);

    opening
        .timeout(_connectTimeout)
        .then((webSocket) {
          if (controller.isClosed) {
            // close() was called while connecting
            webSocket.close();
            return;
          }
          final channel = _channel = IOWebSocketChannel(webSocket);
          final stream = channel.stream.asBroadcastStream();

          _workStreamDone = controller.addStream(
            Rx.concat([
              Stream.value(SocketMessage(SocketMessageType.connected)),
              stream.map(
                (event) => SocketMessage(SocketMessageType.data, event),
              ),
              Rx.defer(
                () => Stream.value(
                  SocketMessage(
                    SocketMessageType.closed,
                    null,
                    channel.closeCode,
                    channel.closeReason,
                  ),
                ),
              ),
            ]),
          );
        })
        // Every failure must reach the stream: listeners wait for the
        // connected message and would otherwise wait forever. Besides
        // SocketException this covers a refused upgrade (WebSocketException,
        // e.g. HTTP 502), TLS errors (HandshakeException) and the timeout.
        .catchError((Object error, StackTrace stackTrace) {
          if (error is TimeoutException) {
            // The socket may still open later; do not leave it open.
            opening.then((webSocket) => webSocket.close(), onError: (_) {});
          }
          if (!controller.isClosed) {
            controller.addError(_mapError(error), stackTrace);
          }
        });
  }

  /// An upgrade refused with 401 or 403 is an authorization failure of the
  /// REST kind, anything else is a [ConnectionException].
  Object _mapError(Object error) {
    if (error is WebSocketException) {
      switch (error.httpStatusCode) {
        case 401:
          return const UnauthorizedException(401, 'unauthorized');
        case 403:
          return const BannedException(403, 'banned');
      }
    }

    return ConnectionException(error.toString());
  }

  /// Can be listened before [connect]
  @override
  Stream<SocketMessage> get messageStream => _controller().stream;

  /// The controller of the current connection, a new one after [close]
  StreamController<SocketMessage> _controller() {
    final current = _streamController;
    if (current != null && !current.isClosed) return current;

    return _streamController = StreamController.broadcast();
  }

  @override
  void sendData(String data) {
    if (_channel == null) {
      throw RemoteIOException(
        'Cannot send data, because socket channel is not opened',
      );
    }

    _channel!.sink.add(data);
  }

  @override
  Future<void> close() async {
    if (_channel != null) {
      await _channel!.sink.close();
      _channel = null;
    }

    if (!(_streamController?.isClosed ?? true)) {
      await _workStreamDone;
      await _streamController!.close();
    }
  }
}
