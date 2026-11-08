@Timeout(Duration(seconds: 5))
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/remote/client/api_exception.dart';
import 'package:lets_play_cities/remote/client/base_socket_connector.dart';
import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:lets_play_cities/remote/game_connection.dart';
import 'package:lets_play_cities/remote/protocol/game_message_codec.dart';
import 'package:lets_play_cities/remote/protocol/game_messages.dart';

const _codec = GameMessageCodec();

const _welcome =
    '{"type":"welcome","user":{"id":7,"name":"Мария","avatarHash":null,'
    '"provider":"native","lastSeenAt":1762560000000}}';

class _FakeConnector implements AbstractSocketConnector {
  final String url;
  final Map<String, String> headers;
  final controller = StreamController<SocketMessage>.broadcast();
  final sent = <String>[];
  bool autoWelcome = true;
  int connects = 0;
  bool closed = false;

  _FakeConnector(this.url, this.headers);

  @override
  void connect() {
    connects++;
    scheduleMicrotask(
      () => controller.add(SocketMessage(SocketMessageType.connected)),
    );
  }

  @override
  Stream<SocketMessage> get messageStream => controller.stream;

  @override
  void sendData(String data) {
    sent.add(data);
    if (autoWelcome && data.contains('"hello"')) {
      scheduleMicrotask(
        () => controller.add(SocketMessage(SocketMessageType.data, _welcome)),
      );
    }
  }

  @override
  Future<void> close() async {
    closed = true;
  }
}

void main() {
  late List<_FakeConnector> connectors;
  late GameConnection connection;
  var name = 'Мария';
  var autoWelcome = true;

  setUp(() {
    autoWelcome = true;
    connectors = [];
    connection = GameConnection(
      url: 'wss://test/v1/game',
      headers: () async => {'Authorization': 'Bearer t'},
      clientName: 'lps-flutter/3.1.0',
      playerName: () => name,
      connectorFactory: (url, headers) {
        final connector = _FakeConnector(url, headers)
          ..autoWelcome = autoWelcome;
        connectors.add(connector);

        return connector;
      },
    );
  });

  test('ensureConnected twice opens one socket and sends one hello', () async {
    final first = connection.ensureConnected();
    final second = connection.ensureConnected();

    final users = await Future.wait([first, second]);
    final third = await connection.ensureConnected();

    expect(connectors, hasLength(1));
    expect(connectors.single.connects, 1);
    expect(connectors.single.headers, {'Authorization': 'Bearer t'});
    expect(connectors.single.sent, hasLength(1));
    expect(
      _codec.decodeClient(connectors.single.sent.single),
      const Hello(protocol: 1, client: 'lps-flutter/3.1.0', name: 'Мария'),
    );
    expect(users.first.id, 7);
    expect(third, same(users.first));
    expect(connection.isConnected, isTrue);
  });

  test('forwards server messages and sends client ones', () async {
    await connection.ensureConnected();
    final next = connection.messages.first;

    connectors.single.controller.add(
      SocketMessage(SocketMessageType.data, '{"type":"queued"}'),
    );
    connection.send(const Find());

    expect(await next, const Queued());
    expect(_codec.decodeClient(connectors.single.sent.last), const Find());
  });

  test('a closed socket reconnects on the next ensureConnected', () async {
    await connection.ensureConnected();
    final closes = connection.closes.first;

    connectors.single.controller.add(
      SocketMessage(SocketMessageType.closed, null, 1001, 'replaced'),
    );

    final close = await closes;
    expect(close.code, 1001);
    expect(close.reason, 'replaced');
    expect(connection.isConnected, isFalse);

    await connection.ensureConnected();
    expect(connectors, hasLength(2));
  });

  test('a failed upgrade fails ensureConnected and allows a retry', () async {
    autoWelcome = false;
    final future = connection.ensureConnected();
    await pumpEventQueue();
    connectors.single.controller.addError(
      const UnauthorizedException(401, 'unauthorized'),
    );

    await expectLater(future, throwsA(isA<UnauthorizedException>()));

    autoWelcome = true;
    final retry = connection.ensureConnected();
    await pumpEventQueue();
    expect(connectors, hasLength(2));
    await retry;
  });

  test('close before the welcome fails ensureConnected', () async {
    autoWelcome = false;
    final future = connection.ensureConnected();
    final failure = expectLater(future, throwsA(isA<ConnectionException>()));
    await pumpEventQueue();

    connectors.single.controller.add(SocketMessage(SocketMessageType.closed));

    await failure;
  });

  test('close() closes the socket', () async {
    await connection.ensureConnected();

    await connection.close();

    expect(connectors.single.closed, isTrue);
    expect(connection.isConnected, isFalse);
  });
}
