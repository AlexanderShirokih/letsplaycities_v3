import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/remote/server/local_game_server.dart';
import 'package:lets_play_cities/remote/server/server_game_controller.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'server_game_controller_test.mocks.dart';

@GenerateNiceMocks([MockSpec<LocalGameServer>(), MockSpec<GamePreferences>()])

void main() {
  late ServerGameController controller;
  late LocalGameServer localGameServer;
  late GamePreferences gamePreferences;

  setUp(() {
    localGameServer = MockLocalGameServer();
    gamePreferences = MockGamePreferences();
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
