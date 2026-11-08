import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:lets_play_cities/remote/auth/token_store.dart';
import 'package:lets_play_cities/remote/client/api_exception.dart';

/// Dio interceptor of the REST API: adds the bearer token, accepts any 2xx
/// answer and turns an error answer into [ApiException] (as the
/// [DioException.error]).
///
/// Requests to other hosts (e.g. the download of an avatar) pass untouched.
class ApiInterceptor extends Interceptor {
  static const _versionPrefix = '/v1';

  final TokenStore _tokens;

  /// Called after an HTTP 401 answer, when the token is no longer valid.
  final void Function() onUnauthorized;

  ApiInterceptor(this._tokens, {required this.onUnauthorized});

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isApiRequest(options)) return handler.next(options);

    // The base URL already ends with the version, don't repeat it.
    final path = options.path;
    if (options.baseUrl.endsWith(_versionPrefix) &&
        (path == _versionPrefix || path.startsWith('$_versionPrefix/'))) {
      options.path = path.substring(_versionPrefix.length);
    }

    final token = await _tokens.read();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    options.validateStatus = (status) =>
        status != null && status >= 200 && status < 300;

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;
    if (!_isApiRequest(err.requestOptions) || response == null) {
      return handler.next(err);
    }

    final exception = _parse(response);
    if (exception is UnauthorizedException) onUnauthorized();

    handler.next(
      DioException(
        requestOptions: err.requestOptions,
        response: response,
        type: err.type,
        error: exception,
        message: exception.toString(),
      ),
    );
  }

  /// Requests with an absolute URL in the path go to somebody else.
  bool _isApiRequest(RequestOptions options) => !options.path.contains('://');

  ApiException _parse(Response<dynamic> response) {
    final status = response.statusCode ?? 0;
    final error = _errorBody(response.data);

    final code = error?['code'];
    final message = error?['message'];
    final resolvedCode = code is String && code.isNotEmpty
        ? code
        : (status == 401 ? 'unauthorized' : 'internal');
    final resolvedMessage = message is String ? message : null;

    if (status == 401 || resolvedCode == 'unauthorized') {
      return UnauthorizedException(status, resolvedCode, resolvedMessage);
    }
    if (resolvedCode == 'banned') {
      return BannedException(status, resolvedCode, resolvedMessage);
    }
    return ApiException(status, resolvedCode, resolvedMessage);
  }

  Map<String, dynamic>? _errorBody(dynamic data) {
    try {
      final decoded = data is String ? jsonDecode(data) : data;
      final error = decoded is Map ? decoded['error'] : null;
      return error is Map ? error.cast<String, dynamic>() : null;
    } on FormatException {
      return null;
    }
  }
}
