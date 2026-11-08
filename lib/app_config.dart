import 'package:equatable/equatable.dart';

/// Defines global app constants, like remote server URL
class AppConfig extends Equatable {
  static const _kHost = String.fromEnvironment('LPS_HOST');
  static const _kPort = int.fromEnvironment('LPS_PORT', defaultValue: 443);
  static const _kSecure = bool.fromEnvironment(
    'LPS_SECURE',
    defaultValue: true,
  );
  static const _kPinCertificate = bool.fromEnvironment('LPS_PIN_CERT');

  /// Path of the protocol version that the main server serves.
  static const _kApiPath = '/v1';

  /// Server URL for REST API requests, e.g. `https://host:443/v1`
  String get restBaseUrl =>
      '${isSecure ? 'https' : 'http'}://$host:$port$_path';

  /// Server URL for game WebSocket, e.g. `wss://host:443/v1/game`
  String get gameSocketUrl =>
      '${isSecure ? 'wss' : 'ws'}://$host:$port$_path/game';

  /// Server origin without the protocol path. Picture URLs of the old
  /// protocol are built from it.
  // replaced in protocol v1 task 3
  String get remotePublicApiURL =>
      '${isSecure ? 'https' : 'http'}://$host:$port';

  /// `true` is server uses HTTPS or WSS connection, `false` is HTTP or WS
  final bool isSecure;

  /// Server host
  final String host;

  /// Server port
  final int port;

  /// `true` if only the certificate from `assets/cert/lps.pem` is trusted
  final bool pinCertificate;

  /// The embedded LAN server serves its paths without the protocol prefix.
  final String _path;

  const AppConfig._(
    this.host,
    this.port,
    this.isSecure,
    this.pinCertificate,
    this._path,
  );

  @override
  List<Object> get props => [host, port, isSecure, pinCertificate, _path];

  /// Reads the main server settings from `--dart-define`:
  /// `LPS_HOST`, `LPS_PORT` (443), `LPS_SECURE` (true), `LPS_PIN_CERT` (false).
  /// Throws [StateError] when `LPS_HOST` is not set.
  factory AppConfig.fromEnvironment() {
    if (_kHost.isEmpty) {
      throw StateError(
        'The server host is not set: build with --dart-define=LPS_HOST=<host>',
      );
    }

    return AppConfig.forHost(
      _kHost,
      port: _kPort,
      isSecure: _kSecure,
      pinCertificate: _kPinCertificate,
    );
  }

  /// Main server at [host].
  factory AppConfig.forHost(
    String host, {
    int port = 443,
    bool isSecure = true,
    bool pinCertificate = false,
  }) => AppConfig._(host, port, isSecure, pinCertificate, _kApiPath);

  /// Game server in the local network: plain HTTP and WS, no pinning.
  // The path becomes `/v1` when the LAN host moves to protocol v1.
  factory AppConfig.lan(String host, {int port = 8988}) =>
      AppConfig._(host, port, false, false, '');

  /// Creates a deep copy with overriding parameters
  AppConfig copy({String? host, int? port, bool? isSecure}) => AppConfig._(
    host ?? this.host,
    port ?? this.port,
    isSecure ?? this.isSecure,
    pinCertificate,
    _path,
  );
}
