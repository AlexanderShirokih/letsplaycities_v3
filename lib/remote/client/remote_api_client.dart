import 'package:dio/dio.dart';
import 'package:lets_play_cities/base/cities_list/city_request.dart';
import 'package:lets_play_cities/remote/auth/token_store.dart';
import 'package:lets_play_cities/remote/client/api_client.dart';
import 'package:lets_play_cities/remote/client/api_exception.dart';
import 'package:lets_play_cities/remote/exceptions.dart';

/// Remote server REST-api client of the city requests
class RemoteLpsApiClient extends LpsApiClient {
  final Dio _httpClient;
  final TokenStore _tokens;

  const RemoteLpsApiClient(this._httpClient, this._tokens);

  @override
  Future<List<CityRequest>> getCityRequests() async {
    await _requireCredential();

    final response = await _send(() => _httpClient.get('/city-edits'));

    return (response.data as List<dynamic>)
        .map((e) => CityRequest.fromJson(e))
        .toList(growable: false);
  }

  @override
  Future<CityRequest> sendCityRequest(SendCityRequest request) async {
    await _requireCredential();

    final response = await _send(
      () => _httpClient.post('/city-edits', data: request.toJson()),
    );

    return CityRequest.fromJson(response.data);
  }

  Future<void> _requireCredential() async {
    final token = await _tokens.read();
    if (token == null || token.isEmpty) {
      throw NotAuthorizedException();
    }
  }

  /// Runs [request]. An answer of the server with an error comes out as the
  /// [ApiException], except a rejected token, which is
  /// [NotAuthorizedException]; a request that got no answer is a
  /// [FetchingException].
  Future<Response<dynamic>> _send(Future<Response> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      final error = e.error;

      if (error is UnauthorizedException) throw NotAuthorizedException();
      if (error is ApiException) throw error;

      throw FetchingException(
        'City requests failed: ${e.message}',
        e.requestOptions.uri,
      );
    }
  }
}

/// Exception used when user is not authorized
class NotAuthorizedException implements Exception {}
