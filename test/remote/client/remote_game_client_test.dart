@Timeout(Duration(seconds: 5))
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/base/game/game_config.dart';
import 'package:lets_play_cities/base/game/game_mode.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/client/base_socket_connector.dart';
import 'package:lets_play_cities/remote/client/remote_game_client.dart';
import 'package:lets_play_cities/remote/client/socket_api.dart';
import 'package:lets_play_cities/remote/core/json_message_converter.dart';
import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:lets_play_cities/remote/model/friend_game_request.dart';

/// In-memory connector: the test pushes incoming messages into [incoming].
class _FakeConnector implements AbstractSocketConnector {
  final incoming = StreamController<SocketMessage>.broadcast();
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

class _FakePreferences extends Fake implements GamePreferences {}

void main() {
  late _FakeConnector connector;
  late RemoteGameClient client;

  /// What the client's `isLocal` callback returns when it is called.
  late bool isLocal;

  setUp(() {
    connector = _FakeConnector();
    isLocal = false;
    client = RemoteGameClient(
      account: RemoteAccount(
        credential: const Credential(userId: 1, accessToken: 'a'),
        name: 'user',
        canReceiveMessages: true,
        role: Role.regular,
        authType: AuthType.native,
        pictureUri: null,
      ),
      socketApi: SocketApi(
        connector,
        JsonMessageConverter(AppConfig.forHost('test')),
      ),
      firebaseToken: Future.value(''),
      preferences: _FakePreferences(),
      isLocal: () => isLocal,
    );
  });

  /// Lets the client subscribe, then drops the connection from the server
  /// side: the socket stream reports `closed` but stays open.
  Future<void> serverClosesConnection() async {
    await pumpEventQueue();
    connector.incoming.add(SocketMessage(SocketMessageType.closed));
  }

  /// Lets the client subscribe, then the server pairs it with an opponent.
  Future<void> opponentJoins() async {
    await pumpEventQueue();
    connector.incoming.add(
      SocketMessage(
        SocketMessageType.data,
        jsonEncode({
          'action': 'join',
          'canReceiveMessages': true,
          'youStarter': true,
          'oppUid': 2,
          'login': 'friend',
          'friendshipStatus': 'friends',
          'authType': 'Native',
          'pictureHash': null,
        }),
      ),
    );
  }

  Matcher configWithMode(GameMode mode) =>
      isA<GameConfig>().having((c) => c.gameMode, 'gameMode', mode);

  const expectedModes = {true: GameMode.multiplayer, false: GameMode.network};

  expectedModes.forEach((local, mode) {
    test('play() starts a ${mode.name} game when isLocal is $local', () async {
      isLocal = local;
      final config = client.play();
      await opponentJoins();

      expect(await config, configWithMode(mode));
    });

    for (final requestType in FriendGameRequestType.values) {
      test('invite() in ${requestType.name} mode starts a ${mode.name} game '
          'when isLocal is $local', () async {
        isLocal = local;
        final config = client.invite(
          FriendGameRequest(
            target: const BaseProfileInfo(userId: 2, login: 'friend'),
            mode: requestType,
          ),
        );
        await opponentJoins();

        expect(await config, configWithMode(mode));
      });
    }
  });

  test('isLocal is read when the opponent joins', () async {
    // false when the client was built and when play() was called
    final config = client.play();
    await pumpEventQueue();
    isLocal = true;
    await opponentJoins();

    expect(await config, configWithMode(GameMode.multiplayer));
  });

  test('play() fails when the connection drops while waiting', () async {
    final failed = expectLater(
      client.play(),
      throwsA(isA<ConnectionException>()),
    );
    await serverClosesConnection();

    await failed;
  });

  for (final mode in FriendGameRequestType.values) {
    test('invite() in ${mode.name} mode fails when the connection drops '
        'while waiting', () async {
      final failed = expectLater(
        client.invite(
          FriendGameRequest(
            target: const BaseProfileInfo(userId: 2, login: 'friend'),
            mode: mode,
          ),
        ),
        throwsA(isA<ConnectionException>()),
      );
      await serverClosesConnection();

      await failed;
    });
  }

  test('play() fails when the client closes the connection', () async {
    final failed = expectLater(
      client.play(),
      throwsA(isA<ConnectionException>()),
    );
    await pumpEventQueue();
    await client.disconnect();

    await failed;
  });
}
