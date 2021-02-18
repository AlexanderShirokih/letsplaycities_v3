import 'package:lets_play_cities/remote/server/back_json_message_converter.dart';
import 'package:lets_play_cities/remote/server/connection_transformer.dart';
import 'package:lets_play_cities/remote/server/remote_connection.dart';
import 'package:lets_play_cities/remote/server/server_connection.dart';
import 'package:lets_play_cities/remote/server/user_lookup_repository.dart';

/// Gate for local API server in remote game mode
/// Provides game server logic for two users.
abstract class LocalGameServer {
  /// Starts the server.
  /// Returns Future that completes when server has started.
  Future<void> startServer();

  /// Waits for all players to be connected and completes the stream.
  Stream<RemoteConnection> getPlayers();

  /// Returns `true` is connection is currently opened
  bool get isStarted;

  /// Closes the server connection
  Future<void> close();
}

/// Implementation of LPS local game server for remote mode
class LocalGameServerImpl extends LocalGameServer {
  final ServerConnection _serverConnection;
  final UserLookupRepository _userLookupRepository;

  LocalGameServerImpl(
    this._serverConnection,
    this._userLookupRepository,
  );

  @override
  Future<void> startServer() => _serverConnection.start();

  @override
  Stream<RemoteConnection> getPlayers() {
    return _serverConnection
        .connect()
        .map((pipe) => ObjectMessagePipe(pipe, BackJsonMessageConverter()))
        .map(
          (pipe) =>
              RemoteConnection.fromMessagePipe(pipe, _userLookupRepository),
        );
  }

  @override
  Future<void> close() async {
    _userLookupRepository.clear();
    await _serverConnection.close();
  }

  @override
  bool get isStarted => _serverConnection.isOpened;
}
