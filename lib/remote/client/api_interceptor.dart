import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:lets_play_cities/remote/auth/token_store.dart';
import 'package:lets_play_cities/remote/client/api_exception.dart';

/// Dio interceptor of the REST API: adds the bearer token, accepts any 2xx
/// answer and turns an error answer into [ApiException] (as the
/// [DioException.error]).
///
/// Requests outside the base URL (e.g. the download of an avatar from a
/// social network) pass untouched.
class ApiInterceptor extends Interceptor {
  static const _versionPrefix = '/v1';
  static const _bearer = 'Bearer ';

  final TokenStore _tokens;

  /// Called after an `unauthorized` answer with the token that the failed
  /// request sent, `null` if it sent none. The error reaches the caller once
  /// the returned future completes.
  final Future<void> Function(String? sentToken) onUnauthorized;

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
      options.headers['Authorization'] = '$_bearer$token';
    }

    options.validateStatus = (status) =>
        status != null && status >= 200 && status < 300;

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    if (!_isApiRequest(err.requestOptions) || response == null) {
      return handler.next(err);
    }

    final exception = _parse(response);
    if (exception is UnauthorizedException) {
      try {
        await onUnauthorized(_sentToken(err.requestOptions));
      } catch (_) {
        // The handler reports its own failures; the caller gets the 401.
      }
    }

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

  /// A request goes to the API when its URL is under the base URL.
  bool _isApiRequest(RequestOptions options) {
    final base = Uri.parse(options.baseUrl);
    final uri = options.uri;

    return uri.scheme == base.scheme &&
        uri.host == base.host &&
        uri.port == base.port &&
        uri.path.startsWith(base.path);
  }

  String? _sentToken(RequestOptions options) {
    final header = options.headers['Authorization'];

    return header is String && header.startsWith(_bearer)
        ? header.substring(_bearer.length)
        : null;
  }

  ApiException _parse(Response<dynamic> response) {
    final status = response.statusCode ?? 0;
    final error = _errorBody(response.data);

    final code = error?['code'];
    final message = error?['message'];
    final resolvedCode = code is String && code.isNotEmpty
        ? code
        : (status == 401 ? 'unauthorized' : 'internal');
    final resolvedMessage = message is String ? message : null;

    // Other 401 codes, like `invalid_provider_token`, keep the session.
    if (resolvedCode == 'unauthorized') {
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
