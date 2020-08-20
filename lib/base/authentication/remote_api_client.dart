import '../auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Remote server REST-api client
class RemoteLpsApiClient extends LpsApiClient {
  final RemoteSignInData _data;
  final String _serverUrl;
  final http.Client _httpClient;

  const RemoteLpsApiClient(this._serverUrl, this._data, this._httpClient);

  @override
  Future<ClientAccountInfo> signUp() async {
    // Send the authorization request
    var responseBody = json.encode(_data.toMap());
    var response =
        await _httpClient.post("$_serverUrl/user/", body: responseBody);

    if (response.statusCode != 200) {
      throw new AuthorizationException.fromStatus(
          response.reasonPhrase, response.statusCode);
    }

    try {
      final decoded = json.decode(response.body);
      final responseData = RemoteSignInResponse.fromMap(decoded);
      return responseData.toClientInfo(_serverUrl);
    } catch (e) {
      throw AuthorizationException("Response error. \n" + e.toString());
    }
  }
}

class RemoteSignInResponse {
  /// Unique user ID.
  /// Used to uniquely identify user on the game server.
  final int userId;

  /// Users name
  final String login;

  /// Access token is used to authenticate user on the server.
  final String accessToken;

  /// Profile picture
  final String pictureHash;

  /// Users role (ex: banned,ready, admin) (legacy names)
  final UserRole role;

  RemoteSignInResponse({
    this.userId,
    this.login,
    this.accessToken,
    this.pictureHash,
    this.role,
  });

  factory RemoteSignInResponse.fromMap(dynamic data) => RemoteSignInResponse(
        userId: int.tryParse(data['userId']),
        login: data['login'],
        accessToken: data['accessToken'],
        pictureHash: data['pictureHash'],
        role: UserRoleExtension.fromString(data['state']),
      );

  ClientAccountInfo toClientInfo(String avatarLookupServer) =>
      ClientAccountInfo(
        credential: Credential(userId: userId, accessToken: accessToken),
        name: login,
        pictureUri: Uri.parse(
            "$avatarLookupServer/user/$userId/picture?hash=$pictureHash"),
      );
}

/// Account state types
enum UserRole { banned, ready, admin }

extension UserRoleExtension on UserRole {
  static UserRole fromString(String s) {
    for (var state in UserRole.values) {
      if (state.toString() == s) return state;
    }
    throw ("Unknown UserRole: $s");
  }
}

/// Request for authentication on the remote game server
class RemoteSignInData {
  /// User name
  String login;

  /// Social network type
  AuthType authType;

  /// Firebase token
  String firebaseToken;

  /// Social network access token
  String accessToken;

  /// Social network user ID
  String snUID;

  /// Protocol version
  static const version = 5;

  dynamic toMap() => {
        "version": version,
        "login": login,
        "authType": authType.name,
        "firebaseToken": firebaseToken,
        "accToken": accessToken,
        "snUID": snUID
      };
}

enum AuthType { Native, Google, Vkontakte, Odnoklassniki, Facebook }

extension AuthTypeExtension on AuthType {
  String get name {
    switch (this) {
      case AuthType.Native:
        return "nv";
      case AuthType.Google:
        return "gl";
      case AuthType.Vkontakte:
        return "vk";
      case AuthType.Odnoklassniki:
        return "ok";
      case AuthType.Facebook:
        return "fb";
      default:
        throw Exception("Unknown AuthType value: $this");
    }
  }
}
