import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:lets_play_cities/remote/server/back_json_message_converter.dart';
import 'package:lets_play_cities/remote/server/connection_transformer.dart';
import 'package:lets_play_cities/remote/server/local_game_server.dart';
import 'package:lets_play_cities/remote/server/remote_connection.dart';
import 'package:lets_play_cities/remote/server/server_game_controller.dart';
import 'package:lets_play_cities/remote/server/user_lookup_repository.dart';
import 'package:lets_play_cities/utils/error_logger.dart';

import 'server_game_controller_test.mocks.dart';

/// Server whose accepted clients are pushed through [players].
class _FakeLocalGameServer implements LocalGameServer {
  final players = StreamController<RemoteConnection>();
  int closeCalls = 0;

  @override
  bool isStarted = false;

  @override
  Future<void> startServer() async => isStarted = true;

  @override
  Stream<RemoteConnection> getPlayers() => players.stream;

  @override
  Future<void> close() async {
    closeCalls++;
    isStarted = false;
    unawaited(players.close());
  }
}

/// Client connection driven by the test.
class _FakeConnection implements RemoteConnection {
  _FakeConnection(
    this.name, {
    required this.onAuthorize,
    Future<void> Function()? onReady,
  }) : onReady = onReady ?? (() async {});

  /// Logs in and asks to play right away.
  _FakeConnection.ready(String name)
    : this(name, onAuthorize: () async => _profile(name));

  /// Connects and never sends anything.
  _FakeConnection.silent(String name)
    : this(name, onAuthorize: () => Completer<ProfileInfo?>().future);

  final String name;
  final Future<ProfileInfo?> Function() onAuthorize;
  final Future<void> Function() onReady;

  final words = StreamController<String>.broadcast();
  final messages = StreamController<String>.broadcast();
  final received = <String>[];
  ProfileInfo? _authorized;
  ProfileInfo? opponent;
  int closeCalls = 0;

  bool get isClosed => closeCalls > 0;

  bool get joined => opponent != null;

  @override
  ProfileInfo get profile => _authorized!;

  @override
  Future<ProfileInfo?> authorize() async => _authorized = await onAuthorize();

  @override
  Future<void> get ready => onReady();

  /// Closing the socket ends its incoming streams.
  @override
  Future<void> close() async {
    closeCalls++;
    await Future.wait([words.close(), messages.close()]);
  }

  @override
  Future<void> join({
    required bool canReceiveMessages,
    required bool youStarter,
    required ProfileInfo opponent,
  }) async => this.opponent = opponent;

  @override
  void sendWord(WordResult wordResult, String city, BaseProfileInfo owner) =>
      received.add('${wordResult.wireName} $city');

  @override
  void sendMessage(String message, BaseProfileInfo owner) =>
      received.add('chat $message');

  @override
  Stream<String> get incomingWords => words.stream;

  @override
  Stream<String> get incomingMessages => messages.stream;

  @override
  String toString() => name;
}

ProfileInfo _profile(String login) => ProfileInfo(
  userId: login.hashCode,
  login: login,
  pictureUrl: '',
  role: Role.regular,
  lastVisitDate: DateTime(2020),
  banStatus: BanStatus.notBanned,
  friendshipStatus: FriendshipStatus.notFriends,
  authType: AuthType.native,
);

/// The WebSocket of a client that the test speaks for. Like a dart:io
/// WebSocket, its incoming stream ends when the client drops, without an
/// error event.
class _ClientSocket extends MessagePipe<String, String> {
  final _incoming = StreamController<String>.broadcast();
  final sent = <String>[];
  int closeCalls = 0;

  void send(Map<String, Object> message) => _incoming.add(jsonEncode(message));

  void drop() => unawaited(_incoming.close());

  @override
  Stream<String> readAllMessages() => _incoming.stream;

  @override
  void sendMessage(String message) => sent.add(message);

  @override
  Future<void> close() async {
    closeCalls++;
    drop();
  }
}

/// The connection the real server builds for [socket].
RemoteConnection _serverSide(
  _ClientSocket socket,
  UserLookupRepository users,
) => RemoteConnection.fromMessagePipe(
  ObjectMessagePipe(socket, BackJsonMessageConverter()),
  users,
);

class _RecordingLogger implements ErrorLogger {
  final errors = <Object>[];
  final logs = <String>[];

  @override
  void error(Object error, StackTrace stackTrace) => errors.add(error);

  @override
  void log(String message) => logs.add(message);
}

/// Lets pending microtasks and zero-delay timers run.
Future<void> _settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late _FakeLocalGameServer server;
  late ServerGameController controller;
  late _RecordingLogger logger;
  late Object? gameError;
  late bool gameFinished;

  void startController({
    Duration handshakeTimeout = const Duration(minutes: 1),
  }) {
    final preferences = MockGamePreferences();
    controller = ServerGameControllerImpl(
      server,
      preferences,
      logger,
      handshakeTimeout: handshakeTimeout,
    );
  }

  Future<void> runGame() async {
    await controller.setUp();
    unawaited(
      controller.runGame().then(
        (_) => gameFinished = true,
        onError: (Object e) {
          gameError = e;
          gameFinished = true;
        },
      ),
    );
  }

  setUp(() {
    server = _FakeLocalGameServer();
    logger = _RecordingLogger();
    gameError = null;
    gameFinished = false;
    startController();
  });

  test('A client that never logs in does not hold up the others', () async {
    final silent = _FakeConnection.silent('silent');
    final host = _FakeConnection.ready('host');
    final guest = _FakeConnection.ready('guest');
    await runGame();

    server.players
      ..add(silent)
      ..add(host)
      ..add(guest);
    await _settle();

    expect(host.opponent?.login, equals('guest'));
    expect(guest.opponent?.login, equals('host'));
    expect(silent.joined, isFalse);

    // The game ends when a player leaves; every connection gets closed
    await guest.close();
    await _settle();

    expect(gameFinished, isTrue);
    expect(gameError, isNull);
    expect([silent.isClosed, host.isClosed], everyElement(isTrue));
    expect(server.closeCalls, equals(1));
  });

  test(
    'A client that stays silent is dropped and logged after the timeout',
    () async {
      startController(handshakeTimeout: const Duration(milliseconds: 20));
      final silent = _FakeConnection.silent('silent');
      await runGame();

      server.players.add(silent);
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(silent.isClosed, isTrue);
      expect(gameFinished, isFalse);
      // Expected from a client, so a message instead of a reported error
      expect(logger.logs, [contains('TimeoutException')]);
      expect(logger.errors, isEmpty);
    },
  );

  test(
    'A client that disconnects during the handshake is logged as a message',
    () async {
      final users = UserLookupRepositoryImpl()..addUser(_profile('late'));
      final early = _ClientSocket();
      final late = _ClientSocket();
      await runGame();

      server.players
        ..add(_serverSide(early, users))
        ..add(_serverSide(late, users));
      await _settle();

      // One drops before it logs in, the other after it but before play
      early.drop();
      late.send({
        'action': 'login',
        'version': 5,
        'uid': _profile('late').userId,
        'canReceiveMessages': true,
        'clientVersion': '1.0',
        'clientBuild': 1,
      });
      await _settle();
      expect(late.sent, [contains('logged_in')]);
      late.drop();
      await _settle();

      expect([early.closeCalls, late.closeCalls], everyElement(isPositive));
      expect(gameFinished, isFalse);
      expect(logger.logs, [
        contains('ClientDisconnectedException'),
        contains('ClientDisconnectedException'),
      ]);
      expect(logger.errors, isEmpty);
    },
  );

  test('A client that breaks the protocol is reported as an error', () async {
    final confused = _ClientSocket();
    await runGame();

    server.players.add(_serverSide(confused, UserLookupRepositoryImpl()));
    await _settle();
    // A word where the server waits for login
    confused.send({'action': 'word', 'word': 'Москва'});
    await _settle();

    expect(confused.closeCalls, isPositive);
    expect(gameFinished, isFalse);
    expect(logger.errors, [isA<TypeError>()]);
    expect(logger.logs, isEmpty);
  });

  test('A failed handshake is logged and drops only that client', () async {
    final host = _FakeConnection.ready('host');
    // A bug on the server side while it waits for play
    final unlucky = _FakeConnection(
      'unlucky',
      onAuthorize: () async => _profile('unlucky'),
      onReady: () async => throw StateError('Bad state'),
    );
    final broken = _FakeConnection(
      'broken',
      onAuthorize: () async =>
          throw const RemoteException('Incompatible protocol versions'),
    );
    final guest = _FakeConnection.ready('guest');
    await runGame();

    server.players
      ..add(host)
      ..add(unlucky)
      ..add(broken);
    await _settle();
    server.players.add(guest);
    await _settle();

    expect(unlucky.isClosed, isTrue);
    expect(broken.isClosed, isTrue);
    expect(host.opponent?.login, equals('guest'));
    expect(guest.opponent?.login, equals('host'));
    expect(gameFinished, isFalse);
    expect(
      logger.errors,
      unorderedEquals([isA<StateError>(), isA<RemoteException>()]),
    );
  });

  test('A client with unknown credentials does not take a seat', () async {
    final host = _FakeConnection.ready('host');
    final stranger = _FakeConnection('stranger', onAuthorize: () async => null);
    final guest = _FakeConnection.ready('guest');
    await runGame();

    server.players
      ..add(host)
      ..add(stranger);
    await _settle();
    server.players.add(guest);
    await _settle();

    expect(stranger.isClosed, isTrue);
    expect(stranger.joined, isFalse);
    expect(host.opponent?.login, equals('guest'));
    expect(guest.opponent?.login, equals('host'));
    // Unknown credentials are an answer, not a failure
    expect(logger.errors, isEmpty);
  });

  test('A failed request is logged and does not end the lobby', () async {
    final host = _FakeConnection.ready('host');
    final guest = _FakeConnection.ready('guest');
    await runGame();

    server.players
      ..add(host)
      ..addError(const FormatException('Bad sign-up body'))
      ..add(guest);
    await _settle();

    expect(host.opponent?.login, equals('guest'));
    expect(guest.opponent?.login, equals('host'));
    expect(gameFinished, isFalse);
    expect(logger.logs, [contains('Bad sign-up body')]);
    expect(logger.errors, isEmpty);
  });

  test('An unexpected request failure is reported as an error', () async {
    final failure = StateError('Bad state');
    await runGame();

    server.players.addError(failure);
    await _settle();

    expect(gameFinished, isFalse);
    expect(logger.errors, [failure]);
    expect(logger.logs, isEmpty);
  });

  test('Clients in the lobby are disconnected when the server stops', () async {
    final host = _FakeConnection.ready('host');
    final pending = _FakeConnection.silent('pending');
    await runGame();

    server.players
      ..add(host)
      ..add(pending);
    await _settle();
    await server.players.close();
    await _settle();

    expect(gameFinished, isTrue);
    expect(host.isClosed, isTrue);
    expect(pending.isClosed, isTrue);
    expect(server.closeCalls, greaterThanOrEqualTo(1));
  });

  test('close() disconnects clients that are still in the lobby', () async {
    final host = _FakeConnection.ready('host');
    final pending = _FakeConnection.silent('pending');
    await runGame();

    server.players
      ..add(host)
      ..add(pending);
    await _settle();
    await controller.close();

    expect(host.isClosed, isTrue);
    expect(pending.isClosed, isTrue);
    expect(server.closeCalls, greaterThanOrEqualTo(1));
  });

  test('A message that cannot be read ends the game for both', () async {
    final host = _FakeConnection.ready('host');
    final guest = _FakeConnection.ready('guest');
    await runGame();

    server.players
      ..add(host)
      ..add(guest);
    await _settle();
    expect(host.joined, isTrue);

    host.words.add('Москва');
    await _settle();
    expect(guest.received, contains('RECEIVED Москва'));

    host.words.addError(
      const UnknownMessageException('Unknown enum type: surrender'),
    );
    await _settle();

    expect(gameFinished, isTrue);
    expect(gameError, isA<UnknownMessageException>());
    expect(host.isClosed, isTrue);
    expect(guest.isClosed, isTrue);
    expect(server.closeCalls, equals(1));
  });

  test('A game that ends late leaves a restarted server running', () async {
    final host = _FakeConnection.ready('host');
    final guest = _FakeConnection.ready('guest');
    await runGame();

    server.players
      ..add(host)
      ..add(guest);
    await _settle();
    expect(host.joined, isTrue);

    // The host starts a new server before the old game has wound down
    await controller.setUp();
    await guest.close();
    await _settle();

    expect(gameFinished, isTrue);
    expect(host.isClosed, isTrue);
    expect(server.closeCalls, isZero);
  });
}
