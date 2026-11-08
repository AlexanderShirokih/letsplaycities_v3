import 'dart:async';

import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/remote/server/client_failure_logging.dart';
import 'package:lets_play_cities/remote/server/local_game_server.dart';
import 'package:lets_play_cities/remote/server/remote_connection.dart';
import 'package:lets_play_cities/utils/error_logger.dart';

/// Container that controls game process
abstract class ServerGameController {
  /// Returns `true` is server is running
  bool get isRunning;

  /// Runs the server
  Future<void> setUp();

  /// Waits for two players, runs the game until one of them leaves, then
  /// closes every accepted connection and the server
  Future<void> runGame();

  /// Closes all resources
  Future<void> close();
}

class ServerGameControllerImpl implements ServerGameController {
  /// How long a client may take to send each handshake message. Generous,
  /// because a client may wait for its push notification token before it
  /// logs in, and that can be slow on a network without internet access.
  static const defaultHandshakeTimeout = Duration(seconds: 60);

  final LocalGameServer _localGameServer;
  final GamePreferences _prefs;

  /// Receives the client failures that the lobby survives: failed requests
  /// and failed handshakes. Failures a client causes on its own are logged as
  /// messages, see [ClientFailureLogging].
  final ErrorLogger _logger;
  final Duration _handshakeTimeout;

  /// Connections accepted and not closed yet. Closing the server does not
  /// close upgraded WebSockets, so they are closed one by one.
  final Set<RemoteConnection> _connections = {};

  /// Changes on every [setUp], so a [runGame] that ends late does not close
  /// a server started after it.
  int _serverGeneration = 0;

  ServerGameControllerImpl(
    this._localGameServer,
    this._prefs,
    this._logger, {
    this._handshakeTimeout = defaultHandshakeTimeout,
  });

  @override
  Future<void> setUp() async {
    _serverGeneration++;
    // Start the server
    await _localGameServer.startServer();
  }

  @override
  Future<void> close() async {
    final connections = List.of(_connections);
    _connections.clear();
    await Future.wait(connections.map(_closeQuietly));
    await _localGameServer.close();
  }

  @override
  Future<void> runGame() async {
    final generation = _serverGeneration;
    final accepted = <RemoteConnection>{};

    try {
      final players = await _waitForPlayers(accepted);

      if (players.length != 2) {
        // The server was closed before two players got ready
        return;
      }

      final room = _Room(players, _prefs.onlineChatEnabled);

      await room.start();

      // Run the game cycle until any opponent disconnects
      await room.runGameCycle();
    } finally {
      await Future.wait(accepted.map(_release));
      if (generation == _serverGeneration) {
        await _localGameServer.close();
      }
    }
  }

  /// Completes with the first two players that finish the handshake, or with
  /// fewer players if the server closes earlier. Every accepted connection is
  /// added to [accepted].
  ///
  /// Handshakes run side by side, so a slow client does not hold up the
  /// others, and the server keeps answering other requests meanwhile.
  Future<List<RemoteConnection>> _waitForPlayers(
    Set<RemoteConnection> accepted,
  ) {
    final readyPlayers = <RemoteConnection>[];
    final lobby = Completer<List<RemoteConnection>>();
    late final StreamSubscription<RemoteConnection> subscription;

    Future<void> admit(RemoteConnection player) async {
      if (!await _handshake(player) || lobby.isCompleted) {
        await _release(player);
        return;
      }

      readyPlayers.add(player);

      if (readyPlayers.length == 2) {
        lobby.complete(List.of(readyPlayers));
        // Stop accepting clients, which also closes the listening socket
        await subscription.cancel();
      }
    }

    subscription = _localGameServer.getPlayers().listen(
      (player) {
        accepted.add(player);
        _connections.add(player);
        unawaited(admit(player));
      },
      // A failed request concerns only the client that sent it, so it is
      // logged and the lobby stays open
      onError: (Object e, StackTrace s) =>
          _logger.clientFailure('LAN request failed', e, s),
      onDone: () {
        if (!lobby.isCompleted) {
          lobby.complete(List.of(readyPlayers));
        }
      },
    );

    return lobby.future;
  }

  /// Returns `true` if [player] logged in and asked to play in time.
  Future<bool> _handshake(RemoteConnection player) async {
    try {
      final profile = await player.authorize().timeout(_handshakeTimeout);
      if (profile == null) {
        return false;
      }

      await player.ready.timeout(_handshakeTimeout);
      return true;
    } catch (e, s) {
      // Timeout, disconnect or protocol error: only this client is dropped
      _logger.clientFailure('LAN handshake failed', e, s);
      return false;
    }
  }

  Future<void> _release(RemoteConnection connection) {
    _connections.remove(connection);
    return _closeQuietly(connection);
  }

  static Future<void> _closeQuietly(RemoteConnection connection) async {
    try {
      await connection.close();
    } catch (_) {
      // The connection is already broken
    }
  }

  @override
  bool get isRunning => _localGameServer.isStarted;
}

class _Room {
  final RemoteConnection _first;
  final RemoteConnection _second;
  final bool _onlineChatEnabled;

  late RemoteConnection _current;

  _Room(List<RemoteConnection> connectedUsers, this._onlineChatEnabled)
    : assert(
        connectedUsers.length == 2,
        'Only two player game supported for now',
      ),
      _first = connectedUsers.first,
      _second = connectedUsers.last;

  // Broadcast join messages to all players
  Future<void> start() async {
    _current = _first;

    await Future.wait([_joinUser(_first, _second), _joinUser(_second, _first)]);
  }

  Future<void> _joinUser(RemoteConnection receiver, RemoteConnection sender) =>
      receiver.join(
        canReceiveMessages: _onlineChatEnabled,
        youStarter: receiver == _first,
        opponent: sender.profile,
      );

  // Runs the game cycle
  Future<void> runGameCycle() async {
    final subscriptions = [
      _forwardIncomingWords(_first, _second),
      _forwardIncomingWords(_second, _first),
      _forwardChatMessages(_first, _second),
      _forwardChatMessages(_second, _first),
    ];

    try {
      // Forward all messages until the first disconnection or the first
      // message that cannot be read
      await Future.any(subscriptions.map((s) => s.asFuture<void>()));
    } finally {
      // Stop forwarding, then close all connections
      await Future.wait(subscriptions.map((s) => s.cancel()));
      await Future.wait([_first.close(), _second.close()]);
    }
  }

  StreamSubscription<String> _forwardChatMessages(
    RemoteConnection sender,
    RemoteConnection target,
  ) => sender.incomingMessages.listen((message) {
    target.sendMessage(message, sender.profile);
  });

  StreamSubscription<String> _forwardIncomingWords(
    RemoteConnection sender,
    RemoteConnection target,
  ) => sender.incomingWords.listen((word) {
    if (sender == _current) {
      // Got input word, broadcast it and switch to the next user
      target.sendWord(WordResult.received, word, sender.profile);
      sender.sendWord(WordResult.accepted, word, sender.profile);
      _current = target;
    } else {
      // Wrong move case. Send an error back to sender
      sender.sendWord(WordResult.wrongMove, word, sender.profile);
    }
  });
}
