import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/base/remote/bloc/local_multiplayer_bloc.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/model/lps_user.dart';
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

/// Answers [getLastSignedInAccount] with [account]
class _FakeAccountManager extends Fake implements AccountManager {
  Future<RemoteAccount?> Function() account = () async => null;

  @override
  Future<RemoteAccount?> getLastSignedInAccount() => account();
}

class _FakePreferences extends Fake implements GamePreferences {
  @override
  String lastNativeLogin = '';
}

RemoteAccount _account(String name) => RemoteAccount(
  LpsUser(id: 7, name: name, provider: 'google', lastSeenAt: DateTime(2026)),
);

Future<void> _settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late _RecordingLogger logger;
  late _FakeAccountManager accounts;
  late _FakePreferences preferences;

  setUp(() {
    logger = _RecordingLogger();
    accounts = _FakeAccountManager();
    preferences = _FakePreferences();
  });

  LocalMultiplayerBloc createBloc(ServerGameController server) =>
      LocalMultiplayerBloc(
        server: server,
        errorLogger: logger,
        accountManager: accounts,
        preferences: preferences,
        defaultPlayerName: 'Игрок',
        accountTimeout: const Duration(milliseconds: 50),
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

    await bloc.close();
  });

  test('Hosts a game on localhost with the LAN server config', () async {
    final server = _FakeServer();
    final bloc = createBloc(server);

    final states = await statesAfter(bloc, LocalMultiplayerCreate());

    expect(states, [
      isA<LocalMultiplayerStartingServer>(),
      LocalMultiplayerStartGame(AppConfig.lan('localhost'), 'Игрок'),
    ]);
    expect(server.calls, ['setUp', 'runGame']);
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

    expect(states, [
      LocalMultiplayerStartGame(AppConfig.lan('192.168.1.10'), 'Игрок'),
    ]);
    expect(server.calls, isEmpty);

    await bloc.close();
  });

  test('Leaving the game stops the host', () async {
    final server = _FakeServer();
    final bloc = createBloc(server);
    await statesAfter(bloc, LocalMultiplayerCreate());

    final states = await statesAfter(bloc, const LocalMultiplayerGameLeft());

    expect(states, [isA<LocalMultiplayerInitial>()]);
    expect(server.calls, ['setUp', 'runGame', 'close']);
    expect(server.isRunning, isFalse);

    await bloc.close();
  });

  test('Leaving a joined game has no host to stop', () async {
    final server = _FakeServer();
    final bloc = createBloc(server);

    await statesAfter(bloc, const LocalMultiplayerGameLeft());

    expect(server.calls, isEmpty);

    await bloc.close();
  });

  test('Closing the bloc closes the server', () async {
    final server = _FakeServer();
    final bloc = createBloc(server);

    await bloc.close();

    expect(server.calls, ['close']);
  });

  group('the player name of the LAN game', () {
    Future<String> nameOfGame() async {
      final bloc = createBloc(_FakeServer());
      final started = bloc.stream
          .firstWhere((state) => state is LocalMultiplayerStartGame)
          .timeout(const Duration(seconds: 5));
      bloc.add(LocalMultiplayerCreate());

      final state = await started as LocalMultiplayerStartGame;
      await bloc.close();

      return state.playerName;
    }

    test('is the name of the signed-in account', () async {
      accounts.account = () async => _account('Google User');
      preferences.lastNativeLogin = 'Вася';

      expect(await nameOfGame(), 'Google User');
    });

    test('is the last native name without an account', () async {
      preferences.lastNativeLogin = ' Вася ';

      expect(await nameOfGame(), 'Вася');
    });

    test('is the last native name when the account fails', () async {
      accounts.account = () async => throw const SocketException('offline');
      preferences.lastNativeLogin = 'Вася';

      expect(await nameOfGame(), 'Вася');
    });

    test('is the last native name when the account does not come', () async {
      accounts.account = () => Completer<RemoteAccount?>().future;
      preferences.lastNativeLogin = 'Вася';

      expect(await nameOfGame(), 'Вася');
    });

    test('is the default name when no name is known', () async {
      accounts.account = () async => throw const SocketException('offline');

      expect(await nameOfGame(), 'Игрок');
    });
  });
}
