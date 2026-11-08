@Timeout(Duration(seconds: 5))
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/client/remote_game_client.dart';
import 'package:lets_play_cities/remote/client/socket_api.dart';
import 'package:lets_play_cities/remote/client/web_socket_connector.dart';
import 'package:lets_play_cities/remote/core/json_message_converter.dart';
import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:lets_play_cities/remote/model/lps_user.dart';

class _FakeWebSocket extends Fake implements WebSocket {
  bool closed = false;

  @override
  Future close([int? code, String? reason]) async => closed = true;
}

class _FakePreferences extends Fake implements GamePreferences {}

const _uri = 'wss://test:443/game';

void main() {
  group('connect() reports a failed connection as ConnectionException', () {
    for (final (name, error) in [
      ('a refused socket', const SocketException('Connection refused')),
      (
        'a refused upgrade (HTTP 502)',
        const WebSocketException('Connection was not upgraded', 502),
      ),
      ('a TLS failure', const HandshakeException('Bad certificate')),
    ]) {
      test(name, () async {
        final connector = WebSocketConnector(
          _uri,
          openSocket: (_) => Future.error(error),
        );

        connector.connect();

        await expectLater(
          connector.messageStream,
          emitsError(isA<ConnectionException>()),
        );
      });
    }

    test('a handshake that does not finish in time', () async {
      final connector = WebSocketConnector(
        _uri,
        openSocket: (_) => Completer<WebSocket>().future,
        connectTimeout: const Duration(milliseconds: 10),
      );

      connector.connect();

      await expectLater(
        connector.messageStream,
        emitsError(isA<ConnectionException>()),
      );
    });
  });

  test('closes a socket that opens after the timeout', () async {
    final opening = Completer<WebSocket>();
    final socket = _FakeWebSocket();
    final connector = WebSocketConnector(
      _uri,
      openSocket: (_) => opening.future,
      connectTimeout: const Duration(milliseconds: 10),
    );

    connector.connect();
    await expectLater(connector.messageStream, emitsError(anything));
    opening.complete(socket);
    await pumpEventQueue();

    expect(socket.closed, isTrue);
  });

  test('closes a socket that opens after close()', () async {
    final opening = Completer<WebSocket>();
    final socket = _FakeWebSocket();
    final connector = WebSocketConnector(
      _uri,
      openSocket: (_) => opening.future,
    );

    connector.connect();
    await connector.close();
    opening.complete(socket);
    await pumpEventQueue();

    expect(socket.closed, isTrue);
  });

  test('RemoteGameClient.connect() fails instead of waiting forever', () async {
    final client = RemoteGameClient(
      account: RemoteAccount(
        LpsUser(
          id: 1,
          name: 'user',
          provider: 'native',
          lastSeenAt: DateTime(2026),
        ),
        canReceiveMessages: true,
      ),
      socketApi: SocketApi(
        WebSocketConnector(
          _uri,
          openSocket: (_) => Future.error(
            const WebSocketException('Connection was not upgraded', 503),
          ),
        ),
        JsonMessageConverter(AppConfig.forHost('test')),
      ),
      firebaseToken: Future.value(''),
      preferences: _FakePreferences(),
      isLocal: () => false,
    );

    await expectLater(client.connect(), throwsA(isA<ConnectionException>()));
  });
}
