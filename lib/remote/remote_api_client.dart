import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'dart:convert';

import 'package:http_parser/http_parser.dart' as http_parser;
import 'package:lets_play_cities/remote/api_client.dart';
import 'package:lets_play_cities/remote/models.dart';
import 'package:lets_play_cities/remote/auth.dart';

/// Remote server REST-api client
class RemoteLpsApiClient extends LpsApiClient {
  final Dio _httpClient;
  final Credential _credential;

  const RemoteLpsApiClient(this._httpClient, this._credential)
      : assert(_httpClient != null);

  @override
  Future<ClientAccountInfo> signUp(RemoteSignInData data) async {
    var responseBody = json.encode(data.toMap());
    final response = await _httpClient.post('/user/', data: responseBody);

    if (response.statusCode != 200) {
      throw AuthorizationException.fromStatus(
          response.statusMessage, response.statusCode);
    }

    try {
      final decoded = json.decode(response.data);
      final responseData = RemoteSignInResponse.fromMap(decoded);
      return responseData.toClientInfo(_httpClient.options.baseUrl);
    } catch (e) {
      throw FetchingException('Response error. \n$e', response.request.uri);
    }
  }

  @override
  Future<List<FriendInfo>> getFriendsList() => _fetchList('friend')
      .then((list) => list.map((e) => FriendInfo.fromJson(e)).toList());

  @override
  Future<List<HistoryInfo>> getHistoryList([int targetId]) =>
      _fetchList('history', targetId)
          .then((list) => list.map((e) => HistoryInfo.fromJson(e)).toList());

  @override
  Future<List<BlackListItemInfo>> getBanList() => _fetchList('blacklist')
      .then((list) => list.map((e) => BlackListItemInfo.fromJson(e)).toList());

  Future<List<dynamic>> _fetchList(String urlPostfix, [int targetId]) async {
    _requireCredential();

    return await _decodeJson(
      () => _httpClient.get(
        targetId == null ? '/$urlPostfix/' : '/$urlPostfix/$targetId',
        options: Options(headers: _credential.asAuthorizationHeader()),
      ),
    ) as List<dynamic>;
  }

  @override
  Future addToBanlist(int userId) async {
    _requireCredential();

    await _requireOK(
      () => _httpClient.put(
        '/blacklist/$userId',
        options: Options(headers: _credential.asAuthorizationHeader()),
      ),
    );
  }

  @override
  Future removeFromBanlist(int userId) async {
    _requireCredential();

    await _requireOK(
      () => _httpClient.delete(
        '/blacklist/$userId',
        options: Options(headers: _credential.asAuthorizationHeader()),
      ),
    );
  }

  @override
  Future deleteFriend(int friendId) async {
    _requireCredential();

    await _requireOK(
      () => _httpClient.delete(
        '/friend/$friendId',
        options: Options(headers: _credential.asAuthorizationHeader()),
      ),
    );
  }

  @override
  Future sendFriendRequest(int friendId, FriendRequestType requestType) async {
    _requireCredential();

    await _requireOK(
      () => _httpClient.put(
        '/friend/request/$friendId/${describeEnum(requestType)}',
        options: Options(headers: _credential.asAuthorizationHeader()),
      ),
    );
  }

  @override
  Future<ProfileInfo> getProfileInfo(int targetId) async {
    _requireCredential();

    targetId ??= _credential.userId;

    return ProfileInfo.fromJson(
      await _decodeJson(
        () => _httpClient.get(
          '/user/$targetId',
          options: Options(headers: _credential.asAuthorizationHeader()),
        ),
      ),
    );
  }

  @override
  Future removePicture() async {
    _requireCredential();
    await _requireOK(
      () => _httpClient.delete(
        '/user/picture',
        options: Options(headers: _credential.asAuthorizationHeader()),
      ),
    );
  }

  @override
  Future updatePicture(List<int> thumbnail, String contentType) async {
    _requireCredential();

    final hash = _getHash(thumbnail);
    final extension = contentType.replaceAll('/', '').replaceAll('image', '');
    final form = FormData.fromMap({
      'hash': hash,
      'imageFile': MultipartFile.fromBytes(
        thumbnail,
        filename: '$hash.$extension',
        contentType: http_parser.MediaType.parse(contentType),
      ),
    });

    await _requireOK(
      () => _httpClient.post(
        '/user/picture/upload',
        options: Options(headers: _credential.asAuthorizationHeader()),
        data: form,
      ),
    );
  }

  String _getHash(List<int> data) {
    var md5 = crypto.md5;
    var digest = md5.convert(data);
    return digest.toString();
  }

  void _requireCredential() {
    if (_credential == null) {
      throw ArgumentError.notNull('credential');
    }
  }

  Future<Response<dynamic>> _requireOK(
    Future<Response> Function() responseSupplier,
  ) async {
    try {
      final response = await responseSupplier();
      if (response.statusCode != 200) {
        throw AuthorizationException.fromStatus(
            response.statusMessage, response.statusCode);
      }
      return response;
    } on DioError catch (e, s) {
      print('API Error: $e,\n at: $s');

      var description = 'no description';

      try {
        final mappedData = e.response.data as Map<String, dynamic>;
        final error = mappedData['error'];
        if (error != null) {
          description = error;
        }
      } catch (_) {}

      throw FetchingException(
          '${e.message}, error=$description', e.request.uri);
    }
  }

  Future<dynamic> _decodeJson(Future<Response> Function() response,
      {bool requireOK = true}) async {
    try {
      if (requireOK) {
        return (await _requireOK(response)).data;
      } else {
        return (await response()).data;
      }
    } on DioError catch (e) {
      throw FetchingException('JSON decoding error. \n$e', e.request.uri);
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

  ClientAccountInfo toClientInfo(String avatarLookupServer) => RemoteAccount(
        credential: Credential(userId: userId, accessToken: accessToken),
        name: login,
        pictureUri:
            '$avatarLookupServer/user/$userId/picture?hash=$pictureHash',
        canReceiveMessages: false,
      );
}

/// Account state types
enum UserRole { banned, ready, admin }

extension UserRoleExtension on UserRole {
  static UserRole fromString(String s) {
    for (var state in UserRole.values) {
      if (state.toString() == s) return state;
    }
    throw ('Unknown UserRole: $s');
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
        'version': version,
        'login': login,
        'authType': authType.name,
        'firebaseToken': firebaseToken,
        'accToken': accessToken,
        'snUID': snUID
      };
}

enum AuthType { Native, Google, Vkontakte, Odnoklassniki, Facebook }

extension AuthTypeExtension on AuthType {
  String get name {
    switch (this) {
      case AuthType.Native:
        return 'nv';
      case AuthType.Google:
        return 'gl';
      case AuthType.Vkontakte:
        return 'vk';
      case AuthType.Odnoklassniki:
        return 'ok';
      case AuthType.Facebook:
        return 'fb';
      default:
        throw Exception('Unknown AuthType value: $this');
    }
  }
}
