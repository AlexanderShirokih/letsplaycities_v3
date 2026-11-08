import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:lets_play_cities/base/usecases.dart';
import 'package:lets_play_cities/remote/auth.dart';

import '../exceptions.dart';

/// Sign ups user by sending REST API request
/// May throw [AuthorizationException] or [FetchingException] if network request
/// fails.
/// Throws [RemoteException] if content type is invalid
class SignUpUser
    implements SingleAsyncUseCase<RemoteSignUpData, RemoteSignUpResponse> {
  final Dio _httpClient;

  SignUpUser(this._httpClient);

  @override
  Future<RemoteSignUpResponse> execute(RemoteSignUpData data) async {
    var responseBody = json.encode(data.toMap());

    try {
      final response = await _httpClient.post('/user/', data: responseBody);

      final status = response.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        throw AuthorizationException.fromStatus(
          response.statusMessage ?? 'No status message',
          response.statusCode ?? 0,
        );
      }

      if (response.data is! Map<String, dynamic>) {
        throw RemoteException(
          '${HttpHeaders.contentTypeHeader}: ${ContentType.json.value} expected',
        );
      }

      final Map<String, dynamic> decoded = response.data;

      if (decoded['error'] != null) {
        throw decoded['error'];
      }

      return RemoteSignUpResponse.fromMap(decoded['data']);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.badResponse) {
        throw AuthorizationException('Message: ${e.message}');
      } else {
        throw FetchingException('Response error.', e.requestOptions.uri);
      }
    }
  }
}
