import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/remote/server/routes/routes.dart';
import 'package:lets_play_cities/utils/error_logger.dart';

class _FakeResponse implements HttpResponse {
  _FakeResponse({this.headersSent = false});

  /// Emulates a response that a handler has already sent.
  final bool headersSent;

  final StringBuffer body = StringBuffer();
  int? _statusCode;
  int closeCalls = 0;

  @override
  int get statusCode => _statusCode ?? HttpStatus.ok;

  @override
  set statusCode(int value) {
    if (headersSent) {
      throw StateError('Header already sent');
    }
    _statusCode = value;
  }

  @override
  void writeln([Object? object = '']) => body.writeln(object);

  @override
  Future close() async => closeCalls++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRequest extends Stream<Uint8List> implements HttpRequest {
  _FakeRequest(this.method, String path, this.response)
    : uri = Uri.parse('http://192.168.1.2:8988$path');

  @override
  final String method;

  @override
  final Uri uri;

  @override
  final _FakeResponse response;

  @override
  StreamSubscription<Uint8List> listen(
    void Function(Uint8List event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => const Stream<Uint8List>.empty().listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ResultHandler implements RequestHandler {
  _ResultHandler(this.result);

  final Object result;

  @override
  Future<dynamic> handleRequest(HttpRequest request) async => result;
}

class _FailingHandler implements RequestHandler {
  _FailingHandler(this.error);

  final Object error;

  @override
  Future<dynamic> handleRequest(HttpRequest request) async => throw error;
}

class _RecordingLogger implements ErrorLogger {
  final errors = <Object>[];
  final logs = <String>[];

  @override
  void error(Object error, StackTrace stackTrace) => errors.add(error);

  @override
  void log(String message) => logs.add(message);
}

void main() {
  late RequestDispatcher dispatcher;
  late _RecordingLogger logger;

  setUp(() {
    logger = _RecordingLogger();
    dispatcher = RequestDispatcherImpl(logger)
      ..bindRequestHandler(
        _ResultHandler('pipe'),
        const Endpoint(HttpMethod.get, '/v1/game'),
      )
      ..bindRequestHandler(
        _FailingHandler(const FormatException('Unexpected end of input')),
        const Endpoint(HttpMethod.get, '/ack'),
      );
  });

  test('Returns the result of the matching handler', () async {
    final request = _FakeRequest('GET', '/v1/game', _FakeResponse());

    expect(await dispatcher.dispatchRequest(request), equals('pipe'));
    expect(request.response.closeCalls, isZero);
    expect(logger.errors, isEmpty);
  });

  test('Answers an unknown path with 400', () async {
    final request = _FakeRequest('GET', '/favicon.ico', _FakeResponse());

    expect(await dispatcher.dispatchRequest(request), isNull);
    expect(request.response.statusCode, equals(HttpStatus.badRequest));
    expect(request.response.closeCalls, equals(1));
    expect(logger.errors, isEmpty);
  });

  test('Answers an unsupported method with 405 instead of throwing', () async {
    final request = _FakeRequest('HEAD', '/v1/game', _FakeResponse());

    expect(await dispatcher.dispatchRequest(request), isNull);
    expect(request.response.statusCode, equals(HttpStatus.methodNotAllowed));
    expect(request.response.closeCalls, equals(1));
    expect(logger.errors, isEmpty);
  });

  test(
    'Answers a malformed request with 400 and logs it as a message',
    () async {
      final request = _FakeRequest('GET', '/ack', _FakeResponse());

      expect(await dispatcher.dispatchRequest(request), isNull);
      expect(request.response.statusCode, equals(HttpStatus.badRequest));
      expect(request.response.body.toString(), contains('Unexpected end'));
      expect(request.response.closeCalls, equals(1));
      expect(logger.logs, [
        allOf(contains('GET /ack'), contains('Unexpected end of input')),
      ]);
      expect(logger.errors, isEmpty);
    },
  );

  test('Does not throw when the failing handler already answered', () async {
    // WebSocketTransformer.upgrade answers 400 itself before it throws, as
    // when a browser opens /game
    dispatcher.bindRequestHandler(
      _FailingHandler(const WebSocketException('Invalid WebSocket upgrade')),
      const Endpoint(HttpMethod.get, '/v1/game'),
    );
    final request = _FakeRequest(
      'GET',
      '/v1/game',
      _FakeResponse(headersSent: true),
    );

    expect(await dispatcher.dispatchRequest(request), isNull);
    expect(logger.logs, [contains('Invalid WebSocket upgrade')]);
    expect(logger.errors, isEmpty);
  });

  test('Logs a client that drops during its request as a message', () async {
    // dart:io fails reading the body of a request whose client goes away
    dispatcher.bindRequestHandler(
      _FailingHandler(
        const HttpException('Connection closed while receiving data'),
      ),
      const Endpoint(HttpMethod.get, '/ack'),
    );
    final request = _FakeRequest('GET', '/ack', _FakeResponse());

    expect(await dispatcher.dispatchRequest(request), isNull);
    expect(logger.logs, [
      allOf(contains('GET /ack'), contains('Connection closed')),
    ]);
    expect(logger.errors, isEmpty);
  });

  test('Reports an unexpected handler failure as an error', () async {
    final failure = StateError('Bad state');
    dispatcher.bindRequestHandler(
      _FailingHandler(failure),
      const Endpoint(HttpMethod.get, '/v1/game'),
    );
    final request = _FakeRequest('GET', '/v1/game', _FakeResponse());

    expect(await dispatcher.dispatchRequest(request), isNull);
    expect(request.response.statusCode, equals(HttpStatus.badRequest));
    expect(logger.errors, [failure]);
    expect(logger.logs, isEmpty);
  });

  test('The built dispatcher serves no route of the old protocol', () async {
    final built = RequestDispatcher.buildRequestDispatcher(logger);

    final game = _FakeRequest('GET', '/game', _FakeResponse());
    expect(await built.dispatchRequest(game), isNull);
    expect(game.response.statusCode, equals(HttpStatus.badRequest));

    final signUp = _FakeRequest('POST', '/user/', _FakeResponse());
    expect(await built.dispatchRequest(signUp), isNull);
    expect(signUp.response.statusCode, equals(HttpStatus.methodNotAllowed));
    expect(logger.errors, isEmpty);
  });
}
