import 'package:lets_play_cities/remote/client/base_socket_connector.dart';
import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:lets_play_cities/remote/model/client_messages.dart';
import 'package:lets_play_cities/remote/model/server_messages.dart';
import 'package:lets_play_cities/remote/server/connection_transformer.dart';

/// Combines transport-level [AbstractSocketConnector] and [MessageConverter]
/// to be able to speak with socket using high-level messages
class SocketApi {
  final AbstractSocketConnector _connector;
  final MessageConverter _converter;

  const SocketApi(this._connector, this._converter);

  /// Initiates connection with WebSocket server
  void connect() => _connector.connect();

  /// Closes current connection to WebSocket server
  Future<void> close() => _connector.close();

  /// Returns stream emitting all incoming messages
  /// Throws [UnknownMessageException] if message cannot be decoded by any reasons
  Stream<ServerMessage> get messages => _connector.messageStream.map((event) {
        switch (event.type) {
          case SocketMessageType.connected:
            return ConnectedMessage();
          case SocketMessageType.data:
            return _converter.decode(event.data!);
          case SocketMessageType.closed:
            return DisconnectedMessage();
          default:
            throw UnknownMessageException('Bad event type: ${event.type}');
        }
      });

  /// Sends encoded message to socket connection
  void sendMessage(ClientMessage message) {
    _connector.sendData(_converter.encode(message));
  }
}
