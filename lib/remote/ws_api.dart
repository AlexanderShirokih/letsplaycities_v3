class WebSocketConnector {
  final String _uri;

  WebSocketConnector(String host, String port) : _uri = 'ws://$host:$port/ws';
}
