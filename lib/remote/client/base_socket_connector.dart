/// Describes socket message types
enum SocketMessageType { connected, data, closed }

/// Container that wraps message.
/// Message types [SocketMessageType.connected] or [SocketMessageType.closed]
/// has no data. [SocketMessageType.closed] carries the WebSocket close code
/// and reason when the peer sent them.
class SocketMessage {
  final SocketMessageType type;
  final String? data;
  final int? closeCode;
  final String? closeReason;

  SocketMessage(this.type, [this.data, this.closeCode, this.closeReason]);
}

abstract class AbstractSocketConnector {
  /// Initiates connection with WebSocket server
  void connect();

  /// Returns stream containing incoming messages
  Stream<SocketMessage> get messageStream;

  /// Sends string message to the socket
  void sendData(String data);

  /// Closes current connection to WebSocket server
  Future<void> close();
}
