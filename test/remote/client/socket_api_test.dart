import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/remote/client/base_socket_connector.dart';
import 'package:lets_play_cities/remote/client/socket_api.dart';
import 'package:lets_play_cities/remote/core/json_message_converter.dart';
import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:lets_play_cities/remote/model/client_messages.dart';
import 'package:lets_play_cities/remote/model/server_messages.dart';

/// In-memory connector: the test pushes incoming frames into [incoming] and
/// reads what was sent from [sent].
class _FakeConnector implements AbstractSocketConnector {
  final incoming = StreamController<SocketMessage>();
  final sent = <String>[];

  @override
  void connect() {}

  @override
  Stream<SocketMessage> get messageStream => incoming.stream;

  @override
  void sendData(String data) => sent.add(data);

  @override
  Future<void> close() => incoming.close();
}

void main() {
  late _FakeConnector connector;
  late SocketApi api;

  setUp(() {
    connector = _FakeConnector();
    api = SocketApi(connector, JsonMessageConverter(AppConfig.forHost('t')));
  });

  test(
    'turns connection events and data frames into server messages',
    () async {
      connector.incoming
        ..add(SocketMessage(SocketMessageType.connected))
        ..add(
          SocketMessage(
            SocketMessageType.data,
            '{"action":"logged_in","newerBuild":512}',
          ),
        )
        ..add(SocketMessage(SocketMessageType.closed))
        ..close();

      await expectLater(
        api.messages,
        emitsInOrder([
          isA<ConnectedMessage>(),
          const LoggedInMessage(newerBuild: 512),
          isA<DisconnectedMessage>(),
          emitsDone,
        ]),
      );
    },
  );

  test('a frame it cannot decode is an error and the next frame still '
      'arrives', () async {
    connector.incoming
      ..add(SocketMessage(SocketMessageType.data, '{"action":"banlist"}'))
      ..add(SocketMessage(SocketMessageType.data, '{"action":"timeout"}'))
      ..close();

    await expectLater(
      api.messages,
      emitsInOrder([
        emitsError(isA<UnknownMessageException>()),
        isA<TimeoutMessage>(),
        emitsDone,
      ]),
    );
  });

  test('sends a client message as JSON text', () {
    api.sendMessage(const OutgoingWordMessage(word: 'москва'));

    expect(connector.sent, ['{"action":"word","word":"москва"}']);
  });
}
