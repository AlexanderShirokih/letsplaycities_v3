//@dart=2.9

import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/remote/server/local_game_server.dart';
import 'package:lets_play_cities/remote/server/server_game_controller.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

class _MockLocalGameServer extends Mock implements LocalGameServer {}

class _MockGamePreferences extends Mock implements GamePreferences {}

void main() {
  ServerGameController controller;
  LocalGameServer localGameServer;
  GamePreferences gamePreferences;

  setUp(() {
    localGameServer = _MockLocalGameServer();
    gamePreferences = _MockGamePreferences();
    controller = ServerGameControllerImpl(localGameServer, gamePreferences);
  });

  test('Controller runs server on setup', () async {
    await expectLater(controller.setUp(), completes);

    verify(localGameServer.startServer()).called(1);
    verifyNoMoreInteractions(localGameServer);
  });

  test('Controller closes the server', () async {
    await expectLater(controller.close(), completes);

    verify(localGameServer.close()).called(1);
    verifyNoMoreInteractions(localGameServer);
  });
}
