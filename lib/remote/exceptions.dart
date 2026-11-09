/// Base class for all exceptions used in remote module
class RemoteException implements Exception {
  final String description;

  const RemoteException(this.description);

  @override
  String toString() => '$runtimeType: $description';
}

/// Indicates that unknown kind of message was received
class UnknownMessageException extends RemoteException {
  const UnknownMessageException(super.description);

  UnknownMessageException.badEnumType(dynamic value)
    : this('Unknown enum type: $value');
}

/// Used as wrapper for SocketException
class ConnectionException extends RemoteException {
  const ConnectionException(super.message);
}

/// Indicates an error in socket transferring
class RemoteIOException extends RemoteException {
  const RemoteIOException(super.description);
}

/// Used when some authorization error happened in REST service
/// or Socket service
class AuthorizationException extends RemoteException {
  AuthorizationException(super.message);

  factory AuthorizationException.fromStatus(
    String reasonPhrase,
    int responseCode,
  ) => AuthorizationException('Status: $responseCode ($reasonPhrase)');
}

/// Thrown when the server refuses a request with HTTP 401, e.g. because the
/// access tokens of the account have expired. The screens show their own
/// text for it; [description] is for logs.
class AccessDeniedException extends AuthorizationException {
  AccessDeniedException() : super('Access denied (HTTP 401)');
}

/// Used when the user is logged in, but the request is intended for another account
class WrongAccountException extends RemoteException {
  const WrongAccountException()
    : super('User logged in another account then intended');
}

/// Used when error happens during REST API fetch requests
class FetchingException extends RemoteException {
  final Uri uri;

  FetchingException(super.message, this.uri);

  @override
  String toString() => 'Fetching exception: $description, URL: $uri';
}
