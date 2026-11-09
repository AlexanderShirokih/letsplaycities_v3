import 'dart:convert';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:lets_play_cities/base/platform/app_version.dart';
import 'package:lets_play_cities/base/platform/device_name.dart';
import 'package:lets_play_cities/remote/server/client_failure_logging.dart';
import 'package:lets_play_cities/remote/server/server_connection.dart';
import 'package:lets_play_cities/utils/error_logger.dart';

/// Describes main HTTP methods
enum HttpMethod {
  get('GET');

  const HttpMethod(this.verb);

  /// Method name as it appears in a request
  final String verb;
}

/// A class that describes endpoint which identifies request 'address'
class Endpoint extends Equatable {
  /// Accepted HTTP method
  final HttpMethod method;

  /// Target URI path;
  final String path;

  const Endpoint(this.method, this.path);

  @override
  List<Object?> get props => [method, path];

  @override
  bool get stringify => true;
}

/// Abstract HTTP request handler
abstract class RequestHandler {
  /// Handles request and returns handling result
  Future<dynamic> handleRequest(HttpRequest request);
}

/// Upgrades current connection to WebSocket and returns its [LanClient]
class WebSocketRequestHandler implements RequestHandler {
  @override
  Future<LanClient> handleRequest(HttpRequest request) async {
    final address = request.connectionInfo?.remoteAddress;
    final socket = await WebSocketTransformer.upgrade(request);

    return LanClient(socket, isHostDevice: address?.isLoopback ?? false);
  }
}

/// Service request used to identify server
class AckServer implements RequestHandler {
  @override
  Future<void> handleRequest(HttpRequest request) async {
    final versionInfo = VersionInfoService.instance;
    final deviceInfo = DeviceNameService.instance.deviceName;

    return await (request.response..writeln(
          jsonEncode({
            'hostName': deviceInfo,
            'version': versionInfo.name,
            'build': versionInfo.build,
          }),
        ))
        .close();
  }
}

/// A class used to dispatch requests to appropriate handlers
abstract class RequestDispatcher {
  /// Binds [RequestHandler] to target [Endpoint]
  void bindRequestHandler(RequestHandler handler, Endpoint endpoint);

  /// Dispatches requests to appropriate [RequestHandler].
  /// Never throws: a request that cannot be handled is answered with an error
  /// response and resolves to `null`, so one bad client cannot stop the server
  /// from handling the others.
  Future<dynamic> dispatchRequest(HttpRequest request);

  /// Create [RequestDispatcher] implementation that binds the routes of the
  /// LAN host, `GET /v1/game` (WebSocket) and `GET /ack`, and reports their
  /// failures to [errorLogger]
  factory RequestDispatcher.buildRequestDispatcher(ErrorLogger errorLogger) {
    return RequestDispatcherImpl(errorLogger)
      ..bindRequestHandler(WebSocketRequestHandler(), gameEndpoint)
      ..bindRequestHandler(AckServer(), Endpoint(HttpMethod.get, '/ack'));
  }

  /// The game WebSocket of protocol v1
  static const gameEndpoint = Endpoint(HttpMethod.get, '/v1/game');
}

/// [RequestDispatcher] that reports the errors of its handlers to an
/// [ErrorLogger] before it answers the request with an error response.
/// Failures a client causes on its own are logged as messages, see
/// [ClientFailureLogging].
class RequestDispatcherImpl implements RequestDispatcher {
  final Map<Endpoint, RequestHandler> _assignments = {};
  final ErrorLogger _logger;

  RequestDispatcherImpl(this._logger);

  @override
  void bindRequestHandler(RequestHandler handler, Endpoint endpoint) {
    _assignments[endpoint] = handler;
  }

  @override
  Future dispatchRequest(HttpRequest request) async {
    final method = _findMethod(request.method);
    if (method == null) {
      await _sendError(
        request,
        HttpStatus.methodNotAllowed,
        'Unsupported HTTP method: ${request.method}',
      );
      return null;
    }

    // Find registered endpoint
    final handler = _assignments[Endpoint(method, request.uri.path)];

    if (handler == null) {
      await _sendError(
        request,
        HttpStatus.badRequest,
        'Appropriate request handler was not found for this request.',
      );
      return null;
    }

    try {
      return await handler.handleRequest(request);
    } catch (e, s) {
      _logger.clientFailure(
        'LAN request ${request.method} ${request.uri.path} failed',
        e,
        s,
      );
      await _sendError(request, HttpStatus.badRequest, 'Error: $e');
      return null;
    }
  }

  Future<void> _sendError(
    HttpRequest request,
    int statusCode,
    String message,
  ) async {
    try {
      await (request.response
            ..statusCode = statusCode
            ..writeln(jsonEncode({'error': message})))
          .close();
    } catch (_) {
      // The response was already sent, as WebSocketTransformer.upgrade does
      // when it rejects a request, or the client has gone away.
    }
  }

  HttpMethod? _findMethod(String method) {
    for (final httpMethod in HttpMethod.values) {
      if (httpMethod.verb == method) {
        return httpMethod;
      }
    }
    return null;
  }
}
