import 'package:equatable/equatable.dart';

/// Defines global app constants, like remote server URL
class AppConfig extends Equatable {
  /// Server URL for REST API requests
  String get remotePublicApiURL =>
      (isSecure ? 'https' : 'http') + '://$host:$port';

  /// Server URL for game WebSocket
  String get remoteWebSocketURL =>
      (isSecure ? 'wss' : 'ws') + '://$host:$port/game';

  /// `true` is server uses HTTPS or WSS connection, `false` is HTTP or WS
  final bool isSecure;

  /// Server host
  final String host;

  /// Server port
  final int port;

  AppConfig._(
    this.host,
    this.port,
    this.isSecure,
  );

  @override
  List<Object> get props => [host, port, isSecure];

  factory AppConfig.forHost(
    String host, {
    int port = 8443,
    bool isSecure = true,
  }) =>
      AppConfig._(host, port, isSecure);

  /// Creates a deep copy with overriding parameters
  AppConfig copy({
    String? host,
    int? port,
    bool? isSecure,
  }) =>
      AppConfig._(
        host ?? this.host,
        port ?? this.port,
        isSecure ?? this.isSecure,
      );
}
