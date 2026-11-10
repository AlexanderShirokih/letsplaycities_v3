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
  static const _kPinCertificate = bool.fromEnvironment('LPS_PIN_CERT');

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

  /// `true` if only the certificate from `assets/cert/lps.pem` is trusted
  final bool pinCertificate;

  const AppConfig._(this.host, this.port, this.isSecure, this.pinCertificate);

  @override
  List<Object> get props => [host, port, isSecure, pinCertificate];

  /// Reads the main server settings from `--dart-define`:
  /// `LPS_HOST` (api.qdstudio.ru), `LPS_PORT` (443), `LPS_SECURE` (true),
  /// `LPS_PIN_CERT` (false).
  factory AppConfig.fromEnvironment() => AppConfig.forHost(
    _kHost,
    port: _kPort,
    isSecure: _kSecure,
    pinCertificate: _kPinCertificate,
  );

  /// Main server at [host].
  factory AppConfig.forHost(
    String host, {
    int port = 443,
    bool isSecure = true,
    bool pinCertificate = false,
  }) => AppConfig._(host, port, isSecure, pinCertificate);

  /// Game server in the local network: plain WS, no pinning.
  factory AppConfig.lan(String host, {int port = lanPort}) =>
      AppConfig._(host, port, false, false);
}
