import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Plays the server for a Dio: answers each `METHOD /path` with the reply
/// set by [on] (404 `not_found` otherwise) and records the requests.
class FakeServer implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  final _replies = <String, (int, Object?)>{};

  /// When `true`, every request fails as if the network were down.
  bool offline = false;

  /// Runs before the reply to a request, e.g. to change the state meanwhile.
  Future<void> Function(RequestOptions request)? beforeReply;

  /// Answers `METHOD path` (the path includes `/v1`) with [status] and the
  /// JSON of [body], or an empty body when [body] is `null`.
  void on(String method, String path, int status, [Object? body]) =>
      _replies['$method $path'] = (status, body);

  /// Answers `METHOD path` with the error body of [code].
  void fail(String method, String path, int status, String code) =>
      on(method, path, status, {
        'error': {'code': code, 'message': 'Server says $code'},
      });

  /// `METHOD /path` of every request
  List<String> get calls => [
    for (final r in requests) '${r.method} ${r.uri.path}',
  ];

  /// Body of the last request to `METHOD path`
  Object? bodyOf(String method, String path) =>
      requests.lastWhere((r) => r.method == method && r.uri.path == path).data;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    await beforeReply?.call(options);

    if (offline) throw const SocketException('Network is unreachable');

    final (status, body) =
        _replies['${options.method} ${options.uri.path}'] ??
        (
          404,
          {
            'error': {'code': 'not_found', 'message': 'Not found'},
          },
        );

    return ResponseBody.fromString(
      body == null ? '' : jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
