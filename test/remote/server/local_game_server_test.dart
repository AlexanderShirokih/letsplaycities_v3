// @dart=2.9

import 'package:lets_play_cities/remote/server/local_game_server.dart';
import 'package:lets_play_cities/remote/server/remote_connection.dart';
import 'package:lets_play_cities/remote/server/server_connection.dart';
import 'package:lets_play_cities/remote/server/user_lookup_repository.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'server_mocks.dart';

class _MockRemoteServerConnection extends Mock implements ServerConnection {}

class _MockLpsServerInteractor extends Mock implements RemoteConnection {}

class _MockUserLookupRepository extends Mock implements UserLookupRepository {}

void main() {
  _MockRemoteServerConnection connection;
  _MockLpsServerInteractor interactor;
  _MockUserLookupRepository repository;
  LocalGameServer apiServer;

  setUp(() {
    connection = _MockRemoteServerConnection();
    interactor = _MockLpsServerInteractor();
    repository = _MockUserLookupRepository();
    apiServer = LocalGameServerImpl(connection, repository);

    when(interactor.authorize()).thenAnswer((_) => Future.value(testProfile));
  });

  test('Server starts and stops correctly', () async {
    await apiServer.startServer();

    verify(connection.start()).called(1);
    verifyNoMoreInteractions(connection);

    await apiServer.close();
    verify(connection.close()).called(1);
    verifyNoMoreInteractions(connection);
  });

  test('Can close when is not started', () async {
    await expectLater(apiServer.close(), completes);
    verify(connection.close()).called(1);
    verifyNoMoreInteractions(connection);
  });

  test('Awaits for opponent', () async {
    when(connection.connect()).thenAnswer((_) => Stream.fromIterable([]));

    await apiServer.startServer();
    verify(connection.start()).called(1);

    await apiServer.getPlayers().toList();

    verify(connection.connect()).called(1);
    verifyNoMoreInteractions(connection);
  });
}
