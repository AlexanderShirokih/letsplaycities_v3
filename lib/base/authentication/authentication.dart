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

  const Credential.empty() : this(userId: 0, accessToken: "");
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

  const ClientAccountInfo.forName(String name)
      : this(credential: const Credential.empty(), name: name, pictureUri: null);
}

/// Used when some authorization error happened
class AuthorizationException implements Exception {
  final String message;

  AuthorizationException(this.message) : assert(message != null);

  factory AuthorizationException.fromStatus(
          String reasonPhrase, int responseCode) =>
      AuthorizationException("Status: $responseCode ($reasonPhrase)");
}
