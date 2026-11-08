import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/base/remote/bloc/local_multiplayer_bloc.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/remote_host.dart';
import 'package:lets_play_cities/remote/server/server_game_controller.dart';
import 'package:lets_play_cities/utils/error_logger.dart';

/// Server that records the calls it gets, in order.
class _FakeServer implements ServerGameController {
  _FakeServer({this.isRunning = false, this.setUpError, this.runGameError});

  @override
  bool isRunning;

  final Object? setUpError;
  final Object? runGameError;

  final calls = <String>[];

  @override
  Future<void> setUp() async {
    calls.add('setUp');
    if (setUpError != null) throw setUpError!;
    isRunning = true;
  }

  @override
  Future<void> runGame() async {
    calls.add('runGame');
    if (runGameError != null) throw runGameError!;
  }

  @override
  Future<void> close() async {
    calls.add('close');
    isRunning = false;
  }
}

class _RecordingLogger implements ErrorLogger {
  final errors = <Object>[];

  @override
  void error(Object error, StackTrace stackTrace) => errors.add(error);

  @override
  void log(String message) {}
}

class _FakeAccountManager extends Fake implements AccountManager {}

final _localConfig = AppConfig.forHost(
  'localhost',
  isSecure: false,
  port: 8988,
);

Future<void> _settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late _RecordingLogger logger;
  late List<AppConfig> accountManagerConfigs;
  late AccountManager accountManager;

  setUp(() {
    logger = _RecordingLogger();
    accountManagerConfigs = [];
    accountManager = _FakeAccountManager();
  });

  LocalMultiplayerBloc createBloc(ServerGameController server) =>
      LocalMultiplayerBloc(
        server: server,
        errorLogger: logger,
        localConfig: _localConfig,
        createAccountManager: (config) {
          accountManagerConfigs.add(config);
          return accountManager;
        },
      );

  Future<List<LocalMultiplayerState>> statesAfter(
    LocalMultiplayerBloc bloc,
    LocalMultiplayerEvent event,
  ) async {
    final states = <LocalMultiplayerState>[];
    final subscription = bloc.stream.listen(states.add);
    bloc.add(event);
    await _settle();
    await subscription.cancel();
    return states;
  }

  test('Stays on the menu when the server cannot start', () async {
    final server = _FakeServer(
      setUpError: const SocketException('Failed to create server socket'),
    );
    final bloc = createBloc(server);

    final states = await statesAfter(bloc, LocalMultiplayerCreate());

    expect(states, [
      isA<LocalMultiplayerStartingServer>(),
      isA<LocalMultiplayerErrorState>(),
      isA<LocalMultiplayerInitial>(),
    ]);
    expect(server.calls, ['setUp', 'close']);
    expect(logger.errors.single, isA<SocketException>());
    expect(accountManagerConfigs, isEmpty);

    await bloc.close();
  });

  test('Hosts a game on localhost with the local server config', () async {
    final server = _FakeServer();
    final bloc = createBloc(server);

    final states = await statesAfter(bloc, LocalMultiplayerCreate());

    final gameConfig = _localConfig.copy(host: 'localhost');
    expect(states, [
      isA<LocalMultiplayerStartingServer>(),
      LocalMultiplayerStartGame(gameConfig, accountManager),
    ]);
    expect(server.calls, ['setUp', 'runGame']);
    expect(accountManagerConfigs, [gameConfig]);
    expect(logger.errors, isEmpty);

    await bloc.close();
  });

  test('Restarts a server that is already running', () async {
    final server = _FakeServer(isRunning: true);
    final bloc = createBloc(server);

    await statesAfter(bloc, LocalMultiplayerCreate());

    expect(server.calls, ['close', 'setUp', 'runGame']);

    await bloc.close();
  });

  test('Logs a game that fails after the server has started', () async {
    final server = _FakeServer(runGameError: StateError('game failed'));
    final bloc = createBloc(server);

    final states = await statesAfter(bloc, LocalMultiplayerCreate());

    expect(states.last, isA<LocalMultiplayerStartGame>());
    expect(logger.errors.single, isA<StateError>());

    await bloc.close();
  });

  test('Joins the chosen host without starting a server', () async {
    final server = _FakeServer();
    final bloc = createBloc(server);
    final host = RemoteHost(
      address: '192.168.1.10',
      versionName: '1.0',
      buildNumber: 1,
      hostName: 'host',
    );

    final states = await statesAfter(bloc, LocalMultiplayerConnect(host));

    final gameConfig = AppConfig.forHost(
      '192.168.1.10',
      isSecure: false,
      port: 8988,
    );
    expect(states, [LocalMultiplayerStartGame(gameConfig, accountManager)]);
    expect(server.calls, isEmpty);
    expect(accountManagerConfigs, [gameConfig]);

    await bloc.close();
  });

  test('Builds a new account manager each time a game starts', () async {
    final bloc = createBloc(_FakeServer());
    expect(accountManagerConfigs, isEmpty);

    await statesAfter(bloc, LocalMultiplayerCreate());
    await statesAfter(bloc, LocalMultiplayerCreate());

    expect(accountManagerConfigs, hasLength(2));

    await bloc.close();
  });

  test('Closing the bloc closes the server', () async {
    final server = _FakeServer();
    final bloc = createBloc(server);

    await bloc.close();

    expect(server.calls, ['close']);
  });
}
