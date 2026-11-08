import 'dart:async';

import 'package:lets_play_cities/remote/client/base_socket_connector.dart';
import 'package:lets_play_cities/remote/client/web_socket_connector.dart';
import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:lets_play_cities/remote/model/lps_user.dart';
import 'package:lets_play_cities/remote/protocol/game_message_codec.dart';
import 'package:lets_play_cities/remote/protocol/game_messages.dart';

/// Creates the transport to [url] that sends [headers] on the upgrade.
typedef GameConnectorFactory = AbstractSocketConnector Function(
  String url,
  Map<String, String> headers,
);

/// How a connection ended: the WebSocket close code and reason, if any
typedef GameConnectionClose = ({int? code, String? reason});

/// The one WebSocket of `WS /v1/game`, shared by everything that talks to the
/// game server. The server keeps a single connection per user and a new one
/// ousts the old one (the user then loses the running game), so the queue,
/// the invitations and the game must all use this socket.
class GameConnection {
  /// The protocol version of `hello`
  static const protocolVersion = 1;

  final String _url;
  final Future<Map<String, String>> Function() _headers;
  final String _clientName;
  final String Function() _playerName;
  final GameConnectorFactory _connectorFactory;
  final GameMessageCodec _codec = const GameMessageCodec();

  final _messages = StreamController<ServerGameMessage>.broadcast();
  final _closes = StreamController<GameConnectionClose>.broadcast();

  AbstractSocketConnector? _connector;
  StreamSubscription<SocketMessage>? _subscription;
  Completer<LpsUser>? _ready;
  bool _welcomed = false;

  GameConnection({
    required this._url,
    required this._headers,
    required this._clientName,
    required this._playerName,
    GameConnectorFactory? connectorFactory,
  }) : _connectorFactory = connectorFactory ?? _webSocketConnector;

  static AbstractSocketConnector _webSocketConnector(
    String url,
    Map<String, String> headers,
  ) => WebSocketConnector(url, headers: headers);

  /// Messages of the server, `welcome` included
  Stream<ServerGameMessage> get messages => _messages.stream;

  /// Emits each time the socket ends, after the connection is reset
  Stream<GameConnectionClose> get closes => _closes.stream;

  /// `true` between the `welcome` and the end of the socket
  bool get isConnected => _welcomed;

  /// Opens the socket and says `hello` unless that is already done. Returns
  /// the user that the server welcomed; the answer is kept for the life of
  /// the socket. Fails with the error of the upgrade (`UnauthorizedException`,
  /// `BannedException`, `ConnectionException`) and then allows a retry.
  Future<LpsUser> ensureConnected() {
    final ready = _ready;
    if (ready != null) return ready.future;

    final completer = _ready = Completer<LpsUser>();
    _open(completer);

    return completer.future;
  }

  Future<void> _open(Completer<LpsUser> completer) async {
    try {
      final headers = await _headers();
      if (_ready != completer) return;

      final connector = _connector = _connectorFactory(_url, headers);
      _subscription = connector.messageStream.listen(
        (event) => _onEvent(connector, completer, event),
        onError: (Object error, StackTrace stackTrace) =>
            _fail(completer, error, stackTrace),
      );
      connector.connect();
    } catch (error, stackTrace) {
      _fail(completer, error, stackTrace);
    }
  }

  void _onEvent(
    AbstractSocketConnector connector,
    Completer<LpsUser> completer,
    SocketMessage event,
  ) {
    switch (event.type) {
      case SocketMessageType.connected:
        connector.sendData(
          _codec.encodeClient(
            Hello(
              protocol: protocolVersion,
              client: _clientName,
              name: _playerName(),
            ),
          ),
        );
      case SocketMessageType.data:
        final ServerGameMessage message;
        try {
          message = _codec.decodeServer(event.data!);
        } on FormatException {
          // Not a message of this protocol; the server stays the authority.
          return;
        }
        if (message is Welcome && !completer.isCompleted) {
          _welcomed = true;
          completer.complete(message.user);
        }
        _messages.add(message);
      case SocketMessageType.closed:
        final wasReady = completer.isCompleted;
        _reset(completer);
        if (!wasReady) {
          completer.completeError(
            ConnectionException(
              'The server closed the socket before the welcome '
              '(${event.closeCode} ${event.closeReason ?? ''})',
            ),
          );
        }
        _closes.add((code: event.closeCode, reason: event.closeReason));
    }
  }

  void _fail(Completer<LpsUser> completer, Object error, StackTrace trace) {
    if (_ready != completer) return;

    _reset(completer);
    if (!completer.isCompleted) completer.completeError(error, trace);
  }

  /// Forgets the socket of [completer] so that the next [ensureConnected]
  /// opens a new one
  void _reset(Completer<LpsUser> completer) {
    if (_ready != completer) return;

    final connector = _connector;
    final subscription = _subscription;
    _ready = null;
    _connector = null;
    _subscription = null;
    _welcomed = false;
    unawaited(() async {
      await subscription?.cancel();
      await connector?.close();
    }());
  }

  /// Sends [message]. Throws [RemoteIOException] unless [isConnected].
  void send(ClientGameMessage message) {
    final connector = _connector;
    if (connector == null || !_welcomed) {
      throw const RemoteIOException('The game connection is not open');
    }

    connector.sendData(_codec.encodeClient(message));
  }

  /// Closes the socket; a later [ensureConnected] opens a new one
  Future<void> close() async {
    final completer = _ready;
    final connector = _connector;
    final subscription = _subscription;
    _ready = null;
    _connector = null;
    _subscription = null;
    _welcomed = false;

    if (completer != null && !completer.isCompleted) {
      completer.completeError(
        const ConnectionException('The game connection was closed'),
      );
    }
    await subscription?.cancel();
    await connector?.close();
  }
}
