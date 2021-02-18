import 'dart:async';
import 'dart:io';

import 'package:lets_play_cities/remote/model/client_messages.dart';
import 'package:lets_play_cities/remote/model/server_messages.dart';

/// Interface for negotiation with client
abstract class MessagePipe<I, O> {
  /// Reads all messages from connection
  Stream<I> readAllMessages();

  /// Reads the next message from connection
  Future<I> readMessage() => readAllMessages().first;

  /// Sends [message] to the connection
  void sendMessage(O message);

  /// Closes connection to the client
  Future<void> close();
}

/// Uses socket connection to communicate with remote client
class WebSocketMessagePipe extends MessagePipe<String, String> {
  final WebSocket _socket;
  final Stream<String> _messagesStream;

  /// Creates [MessagePipe] from existing [Socket].
  WebSocketMessagePipe(this._socket)
      : _messagesStream = _socket.asBroadcastStream().cast<String>();

  @override
  Stream<String> readAllMessages() => _messagesStream;

  @override
  void sendMessage(String message) async {
    _socket.add(message);
  }

  @override
  Future<void> close() async {
    await _socket.close();
  }
}

/// Wraps another Client connector to speak with client using high level
/// [MessageConverter]
class ObjectMessagePipe extends MessagePipe<ClientMessage, ServerMessage> {
  final MessagePipe<String, String> _underlyingTransformer;
  final MessageConverter<ClientMessage, ServerMessage> _converter;

  ObjectMessagePipe(this._underlyingTransformer, this._converter);

  @override
  Stream<ClientMessage> readAllMessages() =>
      _underlyingTransformer.readAllMessages().map(_converter.decode);

  @override
  void sendMessage(ServerMessage message) =>
      _underlyingTransformer.sendMessage(_converter.encode(message));

  @override
  Future<void> close() => _underlyingTransformer.close();
}

/// Message encoder/decoder.
/// Converts raw string message to models back to string
abstract class MessageConverter<I, O> {
  /// Decodes string data to [ServerMessage] instance.
  /// Throws [UnknownMessageException] if message cannot be decoded
  I decode(String data);

  /// Encodes [message] to string.
  String encode(O message);
}
