import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/remote/server/probe/network_discovery.dart';
import 'package:lets_play_cities/utils/error_logger.dart';

/// Reports the port as open only on [openHosts].
class _FakeProbe implements ConnectionProbe {
  _FakeProbe(this.openHosts);

  final Set<String> openHosts;
  final probed = <String>[];

  @override
  Future<bool> testConnection(InternetAddress address) async {
    probed.add(address.address);
    return openHosts.contains(address.address);
  }
}

class _FakeResponse extends Stream<List<int>> implements HttpClientResponse {
  _FakeResponse(this.statusCode, this.chunks);

  @override
  final int statusCode;

  final List<List<int>> chunks;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream.fromIterable(chunks).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRequest implements HttpClientRequest {
  _FakeRequest(this._respond);

  final _FakeResponse Function() _respond;

  @override
  Future<HttpClientResponse> close() async => _respond();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Request whose response never arrives; [abort] fails it like a real one.
class _StalledRequest implements HttpClientRequest {
  final _response = Completer<HttpClientResponse>();
  var aborted = false;

  @override
  Future<HttpClientResponse> close() => _response.future;

  @override
  void abort([Object? exception, StackTrace? stackTrace]) {
    aborted = true;
    if (!_response.isCompleted) {
      _response.completeError(
        exception ?? const HttpException('Request has been aborted'),
        stackTrace,
      );
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Answers /ack by host; an unknown host refuses the connection.
/// A host in [openings] gets its request from there instead.
class _FakeHttpClient implements HttpClient {
  _FakeHttpClient(this.responses, {this.openings = const {}});

  final Map<String, _FakeResponse Function()> responses;
  final Map<String, Future<HttpClientRequest>> openings;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    final opening = openings[url.host];
    if (opening != null) {
      return opening;
    }
    final respond = responses[url.host];
    if (respond == null) {
      throw const SocketException('Connection refused');
    }
    return _FakeRequest(respond);
  }

  @override
  void close({bool force = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingLogger implements ErrorLogger {
  final messages = <String>[];

  @override
  void error(Object error, StackTrace stackTrace) {}

  @override
  void log(String message) => messages.add(message);
}

final _lpsBody = utf8.encode(
  jsonEncode({'hostName': 'iPhone Саша', 'version': '1.2', 'build': 42}),
);

Future<void> _settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

List<String> _candidates(List<String> localAddresses) =>
    NetworkDiscoveryImpl.candidateAddresses(
      localAddresses.map(InternetAddress.new),
    ).map((a) => a.address).toList();

void main() {
  group('candidateAddresses', () {
    test('Covers the /24 subnet of the device, except itself', () {
      final candidates = _candidates(['10.0.5.23']);

      expect(candidates, hasLength(253));
      expect(candidates.first, equals('10.0.5.1'));
      expect(candidates.last, equals('10.0.5.254'));
      expect(candidates, isNot(contains('10.0.5.23')));
    });

    test('Covers each private subnet once and skips other addresses', () {
      final candidates = _candidates([
        '172.20.10.2',
        '172.20.10.5',
        '192.168.43.100',
        '100.64.12.7',
        '169.254.3.4',
        '8.8.8.8',
      ]);

      expect(candidates, hasLength(252 + 253));
      expect(candidates, containsAll(['172.20.10.1', '192.168.43.1']));
      expect(candidates, isNot(contains('172.20.10.2')));
      expect(candidates, isNot(contains('172.20.10.5')));
      expect(candidates.where((a) => a.startsWith('100.64.')), isEmpty);
      expect(candidates.where((a) => a.startsWith('169.254.')), isEmpty);
    });

    test('Falls back to 192.168.0.0 - 192.168.3.255 without a private IP', () {
      final candidates = _candidates(['100.64.12.7']);

      expect(candidates, hasLength(1024));
      expect(candidates.first, equals('192.168.0.0'));
      expect(candidates.last, equals('192.168.3.255'));
    });
  });

  group('scanHosts', () {
    test('Skips hosts that are not LPS servers and keeps scanning', () async {
      final body = _lpsBody;
      final logger = _RecordingLogger();
      // Split inside the two-byte UTF-8 sequence of a Cyrillic letter
      final split = body.indexOf(0xD0) + 1;
      final probe = _FakeProbe({
        '192.168.1.10',
        '192.168.1.11',
        '192.168.1.12',
        '192.168.1.13',
        '192.168.1.14',
        '192.168.1.200',
      });
      final discovery = NetworkDiscoveryImpl(
        port: 8988,
        connectionProbe: probe,
        errorLogger: logger,
        localAddresses: () async => [InternetAddress('192.168.1.5')],
        httpClient: _FakeHttpClient({
          // Another service on the same port
          '192.168.1.10': () => throw const HttpException('Invalid response'),
          '192.168.1.11': () =>
              _FakeResponse(200, [utf8.encode('<html></html>')]),
          '192.168.1.12': () => _FakeResponse(404, []),
          '192.168.1.13': () => _FakeResponse(200, [utf8.encode('[1, 2]')]),
          '192.168.1.14': () =>
              _FakeResponse(200, [body.sublist(0, split), body.sublist(split)]),
          '192.168.1.200': () => _FakeResponse(200, [body]),
        }),
      );

      final hosts = await discovery.scanHosts().toList();

      expect(probe.probed, hasLength(253));
      expect(hosts.map((h) => h.address), ['192.168.1.14', '192.168.1.200']);
      expect(hosts.first.hostName, equals('iPhone Саша'));
      expect(hosts.first.buildNumber, equals(42));
      // Only the 404 is logged; the other failures are not LPS servers
      expect(logger.messages, hasLength(1));
      expect(logger.messages.single, contains('192.168.1.12:8988/ack'));
      expect(logger.messages.single, contains('404'));
    });

    test('Aborts a request whose response does not arrive in time', () async {
      final stalled = _StalledRequest();
      final discovery = NetworkDiscoveryImpl(
        port: 8988,
        connectionProbe: _FakeProbe({'192.168.1.10', '192.168.1.200'}),
        errorLogger: _RecordingLogger(),
        localAddresses: () async => [InternetAddress('192.168.1.5')],
        ackTimeout: const Duration(milliseconds: 30),
        httpClient: _FakeHttpClient(
          {
            '192.168.1.200': () => _FakeResponse(200, [_lpsBody]),
          },
          openings: {'192.168.1.10': Future.value(stalled)},
        ),
      );

      final hosts = await discovery.scanHosts().toList();

      expect(hosts.map((h) => h.address), ['192.168.1.200']);
      expect(stalled.aborted, isTrue);
    });

    test('Aborts a request that opens after the timeout', () async {
      final opening = Completer<HttpClientRequest>();
      final request = _StalledRequest();
      final discovery = NetworkDiscoveryImpl(
        port: 8988,
        connectionProbe: _FakeProbe({'192.168.1.10'}),
        errorLogger: _RecordingLogger(),
        localAddresses: () async => [InternetAddress('192.168.1.5')],
        ackTimeout: const Duration(milliseconds: 30),
        httpClient: _FakeHttpClient(
          const {},
          openings: {'192.168.1.10': opening.future},
        ),
      );

      final hosts = await discovery.scanHosts().toList();
      expect(hosts, isEmpty);

      opening.complete(request);
      await _settle();

      expect(request.aborted, isTrue);
    });

    test('Ignores a request that fails to open after the timeout', () async {
      final opening = Completer<HttpClientRequest>();
      final discovery = NetworkDiscoveryImpl(
        port: 8988,
        connectionProbe: _FakeProbe({'192.168.1.10'}),
        errorLogger: _RecordingLogger(),
        localAddresses: () async => [InternetAddress('192.168.1.5')],
        ackTimeout: const Duration(milliseconds: 30),
        httpClient: _FakeHttpClient(
          const {},
          openings: {'192.168.1.10': opening.future},
        ),
      );

      final hosts = await discovery.scanHosts().toList();
      expect(hosts, isEmpty);

      // Must not surface as an unhandled error and fail the test
      opening.completeError(const SocketException('Connection refused'));
      await _settle();
    });
  });
}
