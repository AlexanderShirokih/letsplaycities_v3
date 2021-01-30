/// Defines global app constants, like remote server URL
class AppConfig {
  /// Server URL for REST API requests
  final String remotePublicApiURL;

  /// Server URL for game WebSocket
  final String remoteWebSocketURL;

  AppConfig._(this.remotePublicApiURL, this.remoteWebSocketURL);

  factory AppConfig.forHost(String host) =>
      AppConfig._('https://$host:8443', 'wss://$host:8443/game');
}
