import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:lets_play_cities/remote/model/client_messages.dart';
import 'package:lets_play_cities/remote/server/back_json_message_converter.dart';
import 'package:lets_play_cities/remote/server/connection_transformer.dart';

/// Pipe whose incoming messages the test controls.
class _FakeStringPipe extends MessagePipe<String, String> {
  final incoming = StreamController<String>.broadcast();

  @override
  Stream<String> readAllMessages() => incoming.stream;

  @override
  void sendMessage(String message) {}

  @override
  Future<void> close() => incoming.close();
}

/// A WebSocket server on the loopback interface that hands each upgraded
/// connection to the test as a [WebSocketMessagePipe].
class _LoopbackServer {
  _LoopbackServer._(this._server) {
    _server.listen(
      (request) async => _pipes.add(
        WebSocketMessagePipe(await WebSocketTransformer.upgrade(request)),
      ),
    );
  }

  final HttpServer _server;
  final _pipes = StreamController<WebSocketMessagePipe>();
  late final _nextPipe = StreamIterator(_pipes.stream);

  static Future<_LoopbackServer> start() async =>
      _LoopbackServer._(await HttpServer.bind(InternetAddress.loopbackIPv4, 0));

  int get port => _server.port;

  Future<WebSocketMessagePipe> nextPipe() async {
    await _nextPipe.moveNext();
    return _nextPipe.current;
  }

  Future<void> close() async {
    await _server.close(force: true);
    await _nextPipe.cancel();
  }
}

/// Opens a raw TCP connection and upgrades it to a WebSocket by hand, so the
/// test can then break the WebSocket protocol or drop the socket.
Future<Socket> _rawWebSocketClient(int port) async {
  final socket = await Socket.connect(InternetAddress.loopbackIPv4, port);
  socket.write(
    'GET /game HTTP/1.1\r\n'
    'Host: localhost:$port\r\n'
    'Upgrade: websocket\r\n'
    'Connection: Upgrade\r\n'
    'Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\n'
    'Sec-WebSocket-Version: 13\r\n'
    '\r\n',
  );
  return socket;
}

void main() {
  group('readMessage', () {
    late _FakeStringPipe pipe;

    setUp(() => pipe = _FakeStringPipe());

    test('Returns the next message', () async {
      final message = pipe.readMessage();
      pipe.incoming.add('hello');

      expect(await message, equals('hello'));
    });

    test('Throws ClientDisconnectedException if the stream ends first', () {
      final message = pipe.readMessage();
      pipe.incoming.close();

      expect(message, throwsA(isA<ClientDisconnectedException>()));
    });

    test('Throws ClientDisconnectedException if the stream has ended', () {
      pipe.incoming.close();

      expect(pipe.readMessage(), throwsA(isA<ClientDisconnectedException>()));
    });

    test('Passes a message that cannot be decoded through unchanged', () {
      final objectPipe = ObjectMessagePipe(pipe, BackJsonMessageConverter());
      final message = objectPipe.readMessage();
      pipe.incoming.add(jsonEncode({'action': 'surrender'}));

      expect(message, throwsA(isA<UnknownMessageException>()));
    });

    test('Reads through ObjectMessagePipe until the stream ends', () async {
      final objectPipe = ObjectMessagePipe(pipe, BackJsonMessageConverter());

      final play = objectPipe.readMessage();
      pipe.incoming.add(jsonEncode({'action': 'play', 'mode': 'RANDOM_PAIR'}));
      expect(await play, isA<PlayMessage>());

      final next = objectPipe.readMessage();
      unawaited(pipe.incoming.close());
      await expectLater(next, throwsA(isA<ClientDisconnectedException>()));
    });
  });

  // dart:io ends a server-side WebSocket stream, without an error event, both
  // when the client closes it and when the connection breaks. These tests
  // pin that, since the LAN server tells a dropped client by it.
  group('WebSocketMessagePipe over a real socket', () {
    late _LoopbackServer server;

    setUp(() async => server = await _LoopbackServer.start());
    tearDown(() => server.close());

    test('A client that closes the WebSocket ends readMessage', () async {
      final pipeFuture = server.nextPipe();
      final client = await WebSocket.connect('ws://127.0.0.1:${server.port}');
      final pipe = await pipeFuture;

      client.add('hello');
      expect(await pipe.readMessage(), equals('hello'));

      final next = pipe.readMessage();
      await client.close();

      await expectLater(next, throwsA(isA<ClientDisconnectedException>()));
    });

    test('A client that drops the socket ends readMessage', () async {
      final pipeFuture = server.nextPipe();
      final client = await _rawWebSocketClient(server.port);
      final pipe = await pipeFuture;

      final next = pipe.readMessage();
      client.destroy();

      await expectLater(next, throwsA(isA<ClientDisconnectedException>()));
    });

    test('A broken WebSocket frame ends readMessage', () async {
      final pipeFuture = server.nextPipe();
      final client = await _rawWebSocketClient(server.port);
      final pipe = await pipeFuture;

      final next = pipe.readMessage();
      // A text frame "hi" without the mask that a client must apply; the
      // server-side transformer fails it as a protocol error
      client.add([0x81, 0x02, 0x68, 0x69]);
      await client.flush();

      await expectLater(next, throwsA(isA<ClientDisconnectedException>()));
      client.destroy();
    });
  });
}
