/// Base class for all exceptions used in remote module
class RemoteException implements Exception {
  final String description;

  const RemoteException(this.description);

  @override
  String toString() => '${runtimeType}: $description';
}

/// Indicates that unknown kind of message was received
class UnknownMessageException extends RemoteException {
  const UnknownMessageException(String description) : super(description);

  UnknownMessageException.badEnumType(dynamic value)
      : this('Unknown enum type: $value');
}

/// Used as wrapper for SocketException
class ConnectionException extends RemoteException {
  const ConnectionException(String message) : super(message);
}

/// Indicates an error in socket transferring
class RemoteIOException extends RemoteException {
  const RemoteIOException(String description) : super(description);
}

/// Used when some authorization error happened in REST service
/// or Socket service
class AuthorizationException extends RemoteException {
  AuthorizationException(String message) : super(message);

  factory AuthorizationException.fromStatus(
          String reasonPhrase, int responseCode) =>
      AuthorizationException('Status: $responseCode ($reasonPhrase)');
}

/// Used when error happens during REST API fetch requests
class FetchingException extends RemoteException {
  final Uri uri;

  FetchingException(String message, this.uri)
      : assert(message != null),
        super(message);

  @override
  String toString() => 'Fetching exception: $description, URL: $uri';
}
