import 'dart:async';

import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:lets_play_cities/remote/game_connection.dart';
import 'package:lets_play_cities/remote/model/lps_user.dart';
import 'package:lets_play_cities/remote/protocol/game_messages.dart';

/// [GameConnection] in memory: the test plays the server with [receive] and
/// [drop] and reads what the client sent from [sent].
class FakeGameConnection implements GameConnection {
  final _messages = StreamController<ServerGameMessage>.broadcast();
  final _closes = StreamController<GameConnectionClose>.broadcast();

  /// Messages the client sent, in order
  final sent = <ClientGameMessage>[];

  /// The user the server welcomes
  LpsUser user;

  /// Calls of [ensureConnected]
  int connects = 0;

  bool _connected = false;

  FakeGameConnection({LpsUser? user})
    : user =
          user ??
          LpsUser(
            id: 1,
            name: 'Мария',
            provider: 'native',
            lastSeenAt: DateTime(2026),
          );

  /// Makes [send] fail
  bool failSend = false;

  /// Makes [ensureConnected] fail with it
  Object? connectError;

  @override
  Future<LpsUser> ensureConnected() async {
    final error = connectError;
    if (error != null) throw error;

    if (!_connected) connects++;
    _connected = true;

    return user;
  }

  @override
  Stream<ServerGameMessage> get messages => _messages.stream;

  @override
  Stream<GameConnectionClose> get closes => _closes.stream;

  @override
  bool get isConnected => _connected;

  @override
  void send(ClientGameMessage message) {
    if (!_connected || failSend) {
      throw const RemoteIOException('The game connection is not open');
    }

    sent.add(message);
  }

  @override
  Future<void> close({String? reason}) async {
    final wasConnected = _connected;
    _connected = false;

    if (reason != null && wasConnected) {
      _closes.add((code: null, reason: reason));
    }
  }

  /// The server sends [message]
  void receive(ServerGameMessage message) => _messages.add(message);

  /// The socket breaks, or the server closes it with [reason]
  void drop({int? code, String reason = 'connection lost'}) {
    _connected = false;
    _closes.add((code: code, reason: reason));
  }
}
