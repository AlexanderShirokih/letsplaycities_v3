/// Authentication service
abstract class LpsApiClient {
  Future<ClientAccountInfo> signUp();

  const LpsApiClient();
}

/// Contains user credentials, which is the result of server authorization.
class Credential {
  /// Unique user ID.
  /// Used to uniquely identify user on the game server.
  final int userId;

  /// Access token is used to authenticate user on the server.
  final String accessToken;

  const Credential({this.userId, this.accessToken});

  const Credential.withUserId(int userId)
      : this(userId: userId, accessToken: "");
}

/// Response from authentication request
class ClientAccountInfo {
  /// User credentials
  final Credential credential;

  /// User name
  final String name;

  /// Profile picture URI
  final Uri pictureUri;

  const ClientAccountInfo({
    this.credential,
    this.name,
    this.pictureUri,
  });

  ClientAccountInfo.basic(String name, int userId)
      : this(credential: Credential.withUserId(userId), name: name);
}

/// Used when some authorization error happened
class AuthorizationException implements Exception {
  final String message;

  AuthorizationException(this.message) : assert(message != null);

  factory AuthorizationException.fromStatus(
          String reasonPhrase, int responseCode) =>
      AuthorizationException("Status: $responseCode ($reasonPhrase)");
}
