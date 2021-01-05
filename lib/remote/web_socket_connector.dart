import 'dart:async';
import 'dart:io';
import 'package:async/async.dart';
import 'package:lets_play_cities/remote/base_socket_connector.dart';
import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:web_socket_channel/io.dart';

/// WebSocket implementation of socket commutator
class WebSocketConnector implements AbstractSocketConnector {
  final String _uri;

  IOWebSocketChannel _channel;
  Future _workStreamDone;

  WebSocketConnector(this._uri);

  StreamController<SocketMessage> _streamController;

  @override
  void connect() {
    if (_channel != null) {
      throw RemoteException(
          'Cannot create new connection while previous does not stopped');
    }

    _streamController = StreamController.broadcast();

    WebSocket.connect(_uri).then((webSocket) {
      _channel = IOWebSocketChannel(webSocket);
      _workStreamDone = _streamController.addStream(StreamGroup.merge([
        Stream.value(SocketMessage(SocketMessageType.connected)),
        _channel.stream
            .map((event) => SocketMessage(SocketMessageType.data, event)),
        Stream.value(SocketMessage(SocketMessageType.closed)),
      ]));
    }).catchError((error, stackTrace) {
      _streamController.addError(
          ConnectionException((error as SocketException).toString()),
          stackTrace);
    }, test: (err) => err is SocketException);
  }

  @override
  Stream<SocketMessage> get messageStream => _streamController.stream;

  @override
  void sendData(String data) {
    if (_channel == null) {
      throw RemoteIOException(
          'Cannot send data, because socket channel is not opened');
    }

    _channel.sink.add(data);
  }

  @override
  Future<void> close() async {
    if (_channel != null) {
      await _channel.sink.close();
      _channel = null;
    }

    if (!_streamController.isClosed) {
      await _workStreamDone;
      await _streamController.close();
    }
  }
}
