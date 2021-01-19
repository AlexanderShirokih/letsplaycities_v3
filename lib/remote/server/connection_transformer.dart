import 'dart:convert';
import 'dart:io';

import 'package:lets_play_cities/remote/client/socket_api.dart';
import 'package:lets_play_cities/remote/model/client_messages.dart';
import 'package:lets_play_cities/remote/model/server_messages.dart';

/// Wrapper for negotiation with client
abstract class MessagePipe<I, O> {
  /// Reads next message from connection
  Future<I> readMessage();

  /// Sends [message] to the connection
  Future<void> sendMessage(O message);

  /// Closes connection to client
  Future<void> close();
}

/// Uses socket connection to communicate with remote client
class WebSocketMessagePipe extends MessagePipe<String, String> {
  final WebSocket _socket;

  /// Creates [MessagePipe] from existing [Socket].
  WebSocketMessagePipe(this._socket);

  @override
  Future<String> readMessage() async {
    final message = await _socket.first;
    return utf8.decode(message);
  }

  @override
  Future<void> sendMessage(String message) async {
    _socket.add(message);
  }

  @override
  Future<void> close() async {
    await _socket.close();
  }
}

/// Wraps another Client connector to speak with client using high level
/// [MessageConverter]
class ConvertableTransformer extends MessagePipe<ClientMessage, ServerMessage> {
  final MessagePipe<String, String> _underlyingTransformer;
  final MessageConverter<ClientMessage, ServerMessage> _converter;

  ConvertableTransformer(this._underlyingTransformer, this._converter);

  @override
  Future<ClientMessage> readMessage() => _underlyingTransformer
      .readMessage()
      .then((json) => _converter.decode(json));

  @override
  Future<void> sendMessage(ServerMessage message) =>
      _underlyingTransformer.sendMessage(_converter.encode(message));

  @override
  Future<void> close() => _underlyingTransformer.close();
}
