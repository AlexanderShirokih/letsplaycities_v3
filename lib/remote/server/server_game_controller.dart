import 'dart:async';

import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/remote/server/local_game_server.dart';
import 'package:lets_play_cities/remote/server/remote_connection.dart';

/// Container that controls game process
abstract class ServerGameController {
  /// Returns `true` is server is running
  bool get isRunning;

  /// Runs the server
  Future<void> setUp();

  /// Runs the game loop until first player surrenders
  Future<void> runGame();

  /// Closes all resources
  Future<void> close();
}

class ServerGameControllerImpl implements ServerGameController {
  final LocalGameServer _localGameServer;
  final GamePreferences _prefs;

  ServerGameControllerImpl(this._localGameServer, this._prefs);

  @override
  Future<void> setUp() async {
    // Start the server
    await _localGameServer.startServer();
  }

  @override
  Future<void> close() async {
    await _localGameServer.close();
  }

  @override
  Future<void> runGame() async {
    // Authenticate users and start the game room
    final startedRoom = await _beginGame();

    if (startedRoom == null) {
      // Cannot start room, exiting
      return await close();
    }

    // Run the game cycle until any opponent disconnects
    await startedRoom.runGameCycle();

    // Close the server
    await close();
  }

  Future<_Room?> _beginGame() async {
    // Take two players and wait until they are ready
    final connectedUsers = await _authorizePlayers();

    if (connectedUsers.length != 2) {
      // May be a cancellation case
      print('Two players required, but only ${connectedUsers.length} present!');
      return null;
    }

    final room = _Room(connectedUsers, _prefs.onlineChatEnabled);

    // Start the room
    await room.start();

    return room;
  }

  Future<List<RemoteConnection>> _authorizePlayers() async {
    final connectedUsers = <RemoteConnection>[];

    await for (final player in _localGameServer.getPlayers().take(2)) {
      final profile = await player.authorize();
      if (profile == null) {
        await player.close();
        continue;
      }

      await player.ready;
      connectedUsers.add(player);
      print("CONNECTED USER (READY):${profile.login}");
    }

    return connectedUsers;
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
      : assert(connectedUsers.length == 2,
            'Only two player game supported for now'),
        _first = connectedUsers.first,
        _second = connectedUsers.last;

  // Broadcast join messages to all players
  Future<void> start() async {
    _current = _first;

    await Future.wait([
      _joinUser(_first, _second),
      _joinUser(_second, _first),
    ]);
  }

  Future<void> _joinUser(
    RemoteConnection receiver,
    RemoteConnection sender,
  ) =>
      receiver.join(
        canReceiveMessages: _onlineChatEnabled,
        youStarter: receiver == _first,
        opponent: sender.profile,
      );

  // Runs the game cycle
  Future<void> runGameCycle() async {
    // Forward all messages and wait for the first disconnection
    await Future.any([
      _forwardIncomingWords(_first, _second).asFuture(),
      _forwardIncomingWords(_second, _first).asFuture(),
      _forwardChatMessages(_first, _second).asFuture(),
      _forwardChatMessages(_second, _first).asFuture(),
    ]);

    // Close all connections
    await Future.wait([_first.close(), _second.close()]);
  }

  StreamSubscription<String> _forwardChatMessages(
    RemoteConnection sender,
    RemoteConnection target,
  ) =>
      sender.incomingMessages.listen((message) {
        target.sendMessage(message, sender.profile);
      });

  StreamSubscription<String> _forwardIncomingWords(
    RemoteConnection sender,
    RemoteConnection target,
  ) =>
      sender.incomingWords.listen((word) {
        if (sender == _current) {
          // Got input word, broadcast it and switch to the next user
          target.sendWord(WordResult.RECEIVED, word, sender.profile);
          sender.sendWord(WordResult.ACCEPTED, word, sender.profile);
          _current = target;
        } else {
          // Wrong move case. Send an error back to sender
          sender.sendWord(WordResult.WRONG_MOVE, word, sender.profile);
        }
      });
}
