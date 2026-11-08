import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:lets_play_cities/base/cities_list/city_request.dart';
import 'package:lets_play_cities/remote/auth/token_store.dart';
import 'package:lets_play_cities/remote/client/api_exception.dart';
import 'package:lets_play_cities/remote/client/api_client.dart';
import 'package:lets_play_cities/remote/exceptions.dart';

/// Remote server REST-api client of the city requests
class RemoteLpsApiClient extends LpsApiClient {
  final Dio _httpClient;
  final TokenStore _tokens;

  const RemoteLpsApiClient(this._httpClient, this._tokens);

  @override
  Future<List<CityRequest>> getCityRequests() async {
    await _requireCredential();

    final data = await _decodeJson(() => _httpClient.get('/cities/edit'));

    return (data as List<dynamic>)
        .map((e) => CityRequest.fromJson(e))
        .toList(growable: false);
  }

  Future<void> _requireCredential() async {
    final token = await _tokens.read();
    if (token == null || token.isEmpty) {
      throw NotAuthorizedException();
    }
  }

  Future<Response<dynamic>> _requireOK(
    Future<Response> Function() responseSupplier,
  ) async {
    try {
      final response = await responseSupplier();

      final status = response.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        throw AuthorizationException.fromStatus(
          response.statusMessage ?? 'No message',
          response.statusCode ?? 0,
        );
      }
      return response;
    } on DioException catch (e) {
      var description = 'no description';

      final apiError = e.error;
      final response = e.response;
      if (apiError is UnauthorizedException) {
        throw AccessDeniedException();
      } else if (apiError is ApiException) {
        description = '${apiError.code}: ${apiError.message}';
      } else if (response == null) {
        description = 'No response!';
      } else if (response.data is String) {
        description = response.data;
      } else {
        description = 'Response if empty or invalid';
      }

      throw FetchingException(
        _getDetailedData(e, description),
        e.requestOptions.uri,
      );
    }
  }

  Future<dynamic> _decodeJson(
    Future<Response> Function() response, {
    bool requireOK = true,
  }) async {
    try {
      if (requireOK) {
        return (await _requireOK(response)).data;
      } else {
        return (await response()).data;
      }
    } on DioException catch (e) {
      throw FetchingException(
        'JSON decoding error. \n$e',
        e.requestOptions.uri,
      );
    }
  }

  String _getDetailedData(DioException e, String description) {
    if (kDebugMode) {
      final stringBuilder = StringBuffer();
      stringBuilder.write('Response Status code: ');
      stringBuilder.writeln(e.response?.statusCode);
      stringBuilder.write('Response Status message: ');
      stringBuilder.writeln(e.response?.statusMessage);
      stringBuilder.write('Request Headers: ');
      stringBuilder.writeln(e.requestOptions.headers);
      stringBuilder.write('Request URI: ');
      stringBuilder.writeln(e.requestOptions.uri);
      stringBuilder.write('Request QueryParams: ');
      stringBuilder.writeln(e.requestOptions.queryParameters);

      return stringBuilder.toString();
    } else {
      return '${e.message}, error=$description';
    }
  }

  @override
  Future<void> sendCityRequest(SendCityRequest request) async {
    await _requireCredential();

    await _requireOK(
      () => _httpClient.post('/cities/edit', data: request.toJson()),
    );
  }
}

/// Exception used when user is not authorized
class NotAuthorizedException implements Exception {}
