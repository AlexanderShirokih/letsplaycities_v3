import 'dart:async';
import 'dart:io';

import 'package:lets_play_cities/remote/client/base_socket_connector.dart';
import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:rxdart/rxdart.dart';
import 'package:web_socket_channel/io.dart';

/// Opens a WebSocket connection to [uri].
typedef WebSocketFactory = Future<WebSocket> Function(String uri);

/// WebSocket implementation of socket commutator
class WebSocketConnector implements AbstractSocketConnector {
  final String _uri;
  final WebSocketFactory _openSocket;
  final Duration _connectTimeout;

  IOWebSocketChannel? _channel;
  Future? _workStreamDone;

  WebSocketConnector(
    this._uri, {
    this._openSocket = WebSocket.connect,
    this._connectTimeout = const Duration(seconds: 10),
  });

  StreamController<SocketMessage>? _streamController;

  @override
  void connect() {
    if (_channel != null) {
      throw RemoteException(
        'Cannot create new connection while previous does not stopped',
      );
    }

    final controller = _streamController = StreamController.broadcast();
    final opening = _openSocket(_uri);

    opening
        .timeout(_connectTimeout)
        .then((webSocket) {
          if (controller.isClosed) {
            // close() was called while connecting
            webSocket.close();
            return;
          }
          _channel = IOWebSocketChannel(webSocket);
          final stream = _channel!.stream.asBroadcastStream();

          _workStreamDone = controller.addStream(
            Rx.concat([
              Stream.value(SocketMessage(SocketMessageType.connected)),
              stream.map(
                (event) => SocketMessage(SocketMessageType.data, event),
              ),
              Stream.value(SocketMessage(SocketMessageType.closed)),
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
            controller.addError(
              ConnectionException(error.toString()),
              stackTrace,
            );
          }
        });
  }

  @override
  Stream<SocketMessage> get messageStream => _streamController!.stream;

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
