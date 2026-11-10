import 'package:equatable/equatable.dart';

/// Defines global app constants, like remote server URL
class AppConfig extends Equatable {
  static const _kHost = String.fromEnvironment(
    'LPS_HOST',
    defaultValue: 'api.qdstudio.ru',
  );
  static const _kPort = int.fromEnvironment('LPS_PORT', defaultValue: 443);
  static const _kSecure = bool.fromEnvironment(
    'LPS_SECURE',
    defaultValue: true,
  );

  /// Path of the protocol version that the servers serve.
  static const _kApiPath = '/v1';

  /// Port of the game server in the local network
  static const lanPort = 8988;

  /// Server URL for REST API requests, e.g. `https://host:443/v1`
  String get restBaseUrl =>
      '${isSecure ? 'https' : 'http'}://$host:$port$_kApiPath';

  /// Server URL for game WebSocket, e.g. `wss://host:443/v1/game`
  String get gameSocketUrl =>
      '${isSecure ? 'wss' : 'ws'}://$host:$port$_kApiPath/game';

  /// `true` is server uses HTTPS or WSS connection, `false` is HTTP or WS
  final bool isSecure;

  /// Server host
  final String host;

  /// Server port
  final int port;

  const AppConfig._(this.host, this.port, this.isSecure);

  @override
  List<Object> get props => [host, port, isSecure];

  /// Reads the main server settings from `--dart-define`:
  /// `LPS_HOST` (api.qdstudio.ru), `LPS_PORT` (443) and `LPS_SECURE` (true).
  factory AppConfig.fromEnvironment() =>
      AppConfig.forHost(_kHost, port: _kPort, isSecure: _kSecure);

  /// Main server at [host].
  factory AppConfig.forHost(
    String host, {
    int port = 443,
    bool isSecure = true,
  }) => AppConfig._(host, port, isSecure);

  /// Game server in the local network: plain WS.
  factory AppConfig.lan(String host, {int port = lanPort}) =>
      AppConfig._(host, port, false);
}
