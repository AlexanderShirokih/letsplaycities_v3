import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:lets_play_cities/remote/client/api_exception.dart';
import 'package:lets_play_cities/remote/model/lps_user.dart';

/// Answer of a sign-in: the session token and the signed-in user
class AuthResult extends Equatable {
  final String token;
  final LpsUser user;

  const AuthResult(this.token, this.user);

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
    json['token'] as String,
    LpsUser.fromJson(json['user'] as Map<String, dynamic>),
  );

  @override
  List<Object?> get props => [token, user];
}

/// Sign-in and the own account on the REST API: `/v1/auth/*` and `/v1/me`.
///
/// An error answer of the server is thrown as [ApiException]; a request that
/// gets no answer throws [DioException].
class AuthApi {
  final Dio _dio;

  AuthApi(this._dio);

  /// Signs in the account of the device [deviceId]. [name] is used only
  /// when the account is created.
  Future<AuthResult> native(String deviceId, String name) =>
      _signIn('/auth/native', {'deviceId': deviceId, 'name': name});

  /// Signs in with the [token] that the social network [provider] gave.
  /// [name] is used only when the account is created.
  Future<AuthResult> social(String provider, String token, String name) =>
      _signIn('/auth/social', {
        'provider': provider,
        'token': token,
        'name': name,
      });

  /// Revokes the token that the requests carry
  Future<void> logout() => _call(() => _dio.post<void>('/auth/logout'));

  Future<LpsUser> me() => _user(() => _dio.get('/me'));

  /// Changes the given fields of the signed-in user
  Future<LpsUser> updateMe({String? name, String? fcmToken}) => _user(
    () => _dio.patch('/me', data: {'name': ?name, 'fcmToken': ?fcmToken}),
  );

  Future<AuthResult> _signIn(String path, Map<String, String> body) async {
    final response = await _call(() => _dio.post(path, data: body));

    return AuthResult.fromJson(response.data as Map<String, dynamic>);
  }

  Future<LpsUser> _user(Future<Response<dynamic>> Function() request) async {
    final response = await _call(request);

    return LpsUser.fromJson(response.data as Map<String, dynamic>);
  }

  Future<T> _call<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (e, s) {
      final error = e.error;
      if (error is ApiException) Error.throwWithStackTrace(error, s);
      rethrow;
    }
  }
}
