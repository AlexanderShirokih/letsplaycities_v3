import 'dart:convert';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:lets_play_cities/base/platform/app_version.dart';
import 'package:lets_play_cities/base/platform/device_name.dart';
import 'package:lets_play_cities/domain/usecases.dart';
import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:lets_play_cities/remote/model/profile_info.dart';
import 'package:lets_play_cities/remote/server/connection_transformer.dart';

import '../user_lookup_repository.dart';

/// Describes main HTTP methods
enum HttpMethod {
  get,
  post,
}

extension HttpMethodNames on HttpMethod {
  /// Returns method name
  String get name {
    switch (this) {
      case HttpMethod.get:
        return 'GET';
      case HttpMethod.post:
        return 'POST';
    }
  }
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

/// Handles Sign-up request. Doesn't return anything
class SignUpRequestHandler implements RequestHandler {
  final SingleAsyncUseCase<HttpRequest, ProfileInfo> _signUpUserUseCase;
  final UserLookupRepository _userLookupRepository;

  SignUpRequestHandler(
    this._signUpUserUseCase,
    this._userLookupRepository,
  );

  @override
  Future<void> handleRequest(HttpRequest request) async {
    final profile = await _signUpUserUseCase.execute(request);
    _userLookupRepository.addUser(profile);
  }
}

/// Upgrades current connection to WebSocket.
/// Returns [MessagePipe<String, String>].
class WebSocketRequestHandler implements RequestHandler {
  @override
  Future<MessagePipe<String, String>> handleRequest(HttpRequest request) async {
    final socket = await WebSocketTransformer.upgrade(request);
    return WebSocketMessagePipe(socket);
  }
}

/// Service request used to identify server
class AckServer implements RequestHandler {
  @override
  Future<void> handleRequest(HttpRequest request) async {
    final versionInfo = VersionInfoService.instance;
    final deviceInfo = DeviceNameService.instance.deviceName;

    return await (request.response
          ..writeln(
            jsonEncode(
              {
                'hostName': deviceInfo,
                'version': versionInfo.name,
                'build': versionInfo.build,
              },
            ),
          ))
        .close();
  }
}

/// A class used to dispatch requests to appropriate handlers
abstract class RequestDispatcher {
  /// Binds [RequestHandler] to target [Endpoint]
  void bindRequestHandler(RequestHandler handler, Endpoint endpoint);

  /// Dispatches requests to appropriate [RequestHandler]
  Future<dynamic> dispatchRequest(HttpRequest request);

  /// Create [RequestDispatcher] implementation that binds all requested
  /// [RequestHandler]s
  factory RequestDispatcher.buildRequestDispatcher(
    SingleAsyncUseCase<HttpRequest, ProfileInfo> signUpUserUseCase,
    UserLookupRepository userLookupRepository,
  ) {
    return RequestDispatcherImpl()
      ..bindRequestHandler(
        SignUpRequestHandler(
          signUpUserUseCase,
          userLookupRepository,
        ),
        Endpoint(HttpMethod.post, '/user/'),
      )
      ..bindRequestHandler(
        WebSocketRequestHandler(),
        Endpoint(HttpMethod.get, '/game'),
      )
      ..bindRequestHandler(
        AckServer(),
        Endpoint(HttpMethod.get, '/ack'),
      );
  }
}

class RequestDispatcherImpl implements RequestDispatcher {
  final Map<Endpoint, RequestHandler> _assignments = {};

  @override
  void bindRequestHandler(RequestHandler handler, Endpoint endpoint) {
    _assignments[endpoint] = handler;
  }

  @override
  Future dispatchRequest(HttpRequest request) async {
    final endpoint = _extractEndpoint(request);

    // Find registered endpoint
    final handler = _assignments[endpoint];

    if (handler == null) {
      await (request.response
            ..statusCode = HttpStatus.badRequest
            ..writeln(
                '{"error": "Appropriate request handler was not found for '
                'this request."}'))
          .close();
      return;
    }

    try {
      return await handler.handleRequest(request);
    } catch (e) {
      await (request.response
            ..statusCode = HttpStatus.badRequest
            ..writeln('{"error":"Error: ${e}"}'))
          .close();
      rethrow;
    }
  }

  Endpoint _extractEndpoint(HttpRequest request) {
    try {
      return Endpoint(_findMethod(request.method), request.uri.path);
    } on StateError {
      // Unsupported HTTP method
      throw RemoteException('Cannot extract endpoint from the given request: '
          '${request.method}: ${request.uri}');
    }
  }

  HttpMethod _findMethod(String method) =>
      HttpMethod.values.firstWhere((httpMethod) => httpMethod.name == method);
}
