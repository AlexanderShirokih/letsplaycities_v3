import 'package:crypto/crypto.dart' as crypto;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart' as http_parser;
import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/base/cities_list/city_request.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/client/api_client.dart';
import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:lets_play_cities/remote/models.dart';
import 'package:lets_play_cities/remote/usecase/signup_user.dart';

/// Remote server REST-api client
class RemoteLpsApiClient extends LpsApiClient {
  final Dio _httpClient;
  final AppConfig _globalAppConfig;
  final CredentialsProvider _credentialsProvider;

  const RemoteLpsApiClient(
    this._globalAppConfig,
    this._httpClient,
    this._credentialsProvider,
  );

  @override
  Future<RemoteSignUpResponse> signUp(RemoteSignUpData data) =>
      SignUpUser(_httpClient).execute(data);

  @override
  Future<List<FriendInfo>> getFriendsList() => _fetchList('friend')
      .then((list) => list.map((e) => FriendInfo.fromJson(e)).toList());

  @override
  Future<List<HistoryInfo>> getHistoryList([int? targetId]) =>
      _fetchList('history', targetId)
          .then((list) => list.map((e) => HistoryInfo.fromJson(e)).toList());

  @override
  Future<List<BlackListItemInfo>> getBanList() => _fetchList('blacklist')
      .then((list) => list.map((e) => BlackListItemInfo.fromJson(e)).toList());

  Credential getCredentials() {
    return _credentialsProvider.getCredentials();
  }

  Future<List<dynamic>> _fetchList(String urlPostfix, [int? targetId]) async {
    _requireCredential();
    final isOwner = getCredentials().userId == targetId;

    return await _decodeJson(
      () => _httpClient.get(
        targetId == null || isOwner
            ? '/$urlPostfix/'
            : '/$urlPostfix/$targetId',
        options: Options(headers: getCredentials().asAuthorizationHeader()),
      ),
    ) as List<dynamic>;
  }

  @override
  Future addToBanlist(int userId) async {
    _requireCredential();

    await _requireOK(
      () => _httpClient.put(
        '/blacklist/$userId',
        options: Options(headers: getCredentials().asAuthorizationHeader()),
      ),
    );
  }

  @override
  Future removeFromBanlist(int userId) async {
    _requireCredential();

    await _requireOK(
      () => _httpClient.delete(
        '/blacklist/$userId',
        options: Options(headers: getCredentials().asAuthorizationHeader()),
      ),
    );
  }

  @override
  Future deleteFriend(int friendId) async {
    _requireCredential();

    await _requireOK(
      () => _httpClient.delete(
        '/friend/$friendId',
        options: Options(headers: getCredentials().asAuthorizationHeader()),
      ),
    );
  }

  @override
  Future sendFriendRequest(int friendId, FriendRequestType requestType) async {
    _requireCredential();

    await _requireOK(
      () => _httpClient.put(
        '/friend/request/$friendId/${describeEnum(requestType)}',
        options: Options(headers: getCredentials().asAuthorizationHeader()),
      ),
    );
  }

  @override
  Future<void> declineGameRequest(int requesterId) async {
    _requireCredential();
    await _requireOK(
      () => _httpClient.put(
        '/user/request/$requesterId/DENY',
        options: Options(headers: getCredentials().asAuthorizationHeader()),
      ),
    );
  }

  @override
  Future<ProfileInfo> getProfileInfo(int? targetId) async {
    _requireCredential();

    targetId ??= getCredentials().userId;

    return ProfileInfo.fromJson(
      _globalAppConfig,
      await _decodeJson(
        () => _httpClient.get(
          '/user/$targetId',
          options: Options(headers: getCredentials().asAuthorizationHeader()),
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
        options: Options(headers: getCredentials().asAuthorizationHeader()),
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
        options: Options(headers: getCredentials().asAuthorizationHeader()),
        data: form,
      ),
    );
  }

  @override
  Future<List<CityRequest>> getCityRequests() async {
    _requireCredential();

    final data = await _decodeJson(
      () => _httpClient.get(
        '/cities/edit',
        options: Options(headers: getCredentials().asAuthorizationHeader()),
      ),
    );

    return (data as List<dynamic>)
        .map((e) => CityRequest.fromJson(e))
        .toList(growable: false);
  }

  String _getHash(List<int> data) {
    var md5 = crypto.md5;
    var digest = md5.convert(data);
    return digest.toString();
  }

  void _requireCredential() {
    if (getCredentials().userId == 0 && getCredentials().accessToken.isEmpty) {
      throw NotAuthorizedException();
    }
  }

  Future<Response<dynamic>> _requireOK(
    Future<Response> Function() responseSupplier,
  ) async {
    try {
      final response = await responseSupplier();

      if (response.statusCode != 200) {
        throw AuthorizationException.fromStatus(
            response.statusMessage ?? 'No message', response.statusCode ?? 0);
      }
      return response;
    } on DioError catch (e) {
      var description = 'no description';

      final response = e.response;
      if (response == null) {
        description = 'No response!';
      } else {
        if (response.statusCode == 401) {
          throw AuthorizationException(
              'У вас нет доступа к получению информации. Возможно истек срок жизни токенов доступа. Попробуйте очистить данные приложения');
        }

        if (response.data is String) {
          description = response.data;
        } else if (response.data is Map<String, dynamic>) {
          final mappedData = response.data as Map<String, dynamic>;
          final error = mappedData['error'];
          description = error ?? 'Description is not provided';
        } else {
          description = 'Response if empty or invalid';
        }
      }

      throw FetchingException(_getDetailedData(e, description), e.request!.uri);
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
      throw FetchingException('JSON decoding error. \n$e', e.request!.uri);
    }
  }

  String _getDetailedData(DioError e, String description) {
    if (kDebugMode) {
      final stringBuilder = StringBuffer();
      stringBuilder.write('Response Status code: ');
      stringBuilder.writeln(e.response?.statusCode);
      stringBuilder.write('Response Status message: ');
      stringBuilder.writeln(e.response?.statusMessage);
      stringBuilder.write('Request Headers: ');
      stringBuilder.writeln(e.request?.headers);
      stringBuilder.write('Request URI: ');
      stringBuilder.writeln(e.request?.uri);
      stringBuilder.write('Request QueryParams: ');
      stringBuilder.writeln(e.request?.queryParameters);

      return stringBuilder.toString();
    } else {
      return '${e.message}, error=$description';
    }
  }

  @override
  Future<void> sendCityRequest(SendCityRequest request) async {
    _requireCredential();

    await _requireOK(
      () => _httpClient.post(
        '/cities/edit',
        options: Options(headers: getCredentials().asAuthorizationHeader()),
        data: request.toJson(),
      ),
    );
  }
}

class RemoteSignUpResponse {
  /// Unique user ID.
  /// Used to uniquely identify user on the game server.
  final int userId;

  /// Users name
  final String login;

  /// Access token is used to authenticate user on the server.
  final String accessToken;

  /// Profile picture
  final String pictureHash;

  /// Users role on server
  final Role role;

  final AuthType authType;

  RemoteSignUpResponse({
    required this.userId,
    required this.login,
    required this.accessToken,
    required this.pictureHash,
    required this.role,
    required this.authType,
  });

  factory RemoteSignUpResponse.fromMap(dynamic data) => RemoteSignUpResponse(
        userId: data['userId'],
        login: data['name'],
        accessToken: data['accHash'],
        pictureHash: data['picHash'],
        role: UserRoleExtension.fromString(data['state']),
        authType: AuthTypeExtension.fromString(data['authType']),
      );

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'name': login,
        'accHash': accessToken,
        'picHash': pictureHash,
        'state': role.name,
        'authType': authType.fullName,
      };
}

extension UserRoleExtension on Role {
  static Role fromString(String s) {
    switch (s) {
      case 'banned':
        return Role.banned;
      case 'ready':
        return Role.regular;
      case 'admin':
        return Role.admin;
      default:
        throw ('Unknown UserRole: $s');
    }
  }

  String get name {
    switch (this) {
      case Role.banned:
        return 'banned';
      case Role.regular:
        return 'ready';
      case Role.admin:
        return 'admin';
    }
  }
}

/// Request for authentication on the remote game server
class RemoteSignUpData {
  /// User name
  final String login;

  /// Social network type
  final AuthType authType;

  /// Firebase token
  final String firebaseToken;

  /// Social network access token
  final String accessToken;

  /// Social network user ID
  final String snUID;

  /// Protocol version
  static const version = 5;

  RemoteSignUpData({
    required this.login,
    required this.authType,
    required this.firebaseToken,
    required this.accessToken,
    required this.snUID,
  });

  dynamic toMap() => {
        'version': version,
        'login': login,
        'authType': authType.fullName,
        'firebaseToken': firebaseToken,
        'accToken': accessToken,
        'snUID': snUID
      };

  factory RemoteSignUpData.fromMap(Map<String, dynamic> json) =>
      RemoteSignUpData(
        authType: AuthTypeExtension.fromString(json['authType']),
        login: json['login'],
        accessToken: json['accToken'],
        firebaseToken: json['firebaseToken'],
        snUID: json['snUID'],
      );
}

/// Exception used when user is not authorized
class NotAuthorizedException implements Exception {}
