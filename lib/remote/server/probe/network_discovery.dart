import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:lets_play_cities/remote/remote_host.dart';
import 'package:lets_play_cities/utils/error_logger.dart';

/// Network connection tester
abstract class ConnectionProbe {
  /// Tests connection and returns `true` is connection is available
  Future<bool> testConnection(InternetAddress address);
}

class ConnectionProbeImpl implements ConnectionProbe {
  /// Scanning port
  final int port;

  /// Maximum address ping timeout
  final Duration timeout;

  ConnectionProbeImpl(this.port, this.timeout);

  @override
  Future<bool> testConnection(InternetAddress address) async {
    try {
      final s = await Socket.connect(address, port, timeout: timeout);
      s.destroy();
      // Socket successfully opened on the requested port
      return true;
    } on SocketException {
      // Skip bad sockets
      return false;
    }
  }
}

/// Service used to ping devices in local network
abstract class NetworkDiscovery {
  /// Scanning port
  final int port;

  NetworkDiscovery(this.port);

  /// Scans hosts for running LPS local servers
  Stream<RemoteHost> scanHosts();

  /// Closes internal [HttpClient]
  void close();

  factory NetworkDiscovery.createDiscovery({
    Duration timeout = const Duration(milliseconds: 500),
    required int port,
    required ErrorLogger errorLogger,
  }) => NetworkDiscoveryImpl(
    port: port,
    connectionProbe: ConnectionProbeImpl(port, timeout),
    httpClient: HttpClient(),
    errorLogger: errorLogger,
  );
}

/// Returns the IPv4 addresses of this device's network interfaces
typedef LocalAddressesProvider = Future<List<InternetAddress>> Function();

class NetworkDiscoveryImpl extends NetworkDiscovery {
  /// Range scanned when the device has no private IPv4 address:
  /// 192.168.0.0 - 192.168.3.255
  static const int _fallbackBaseIP = 0xC0A80000;
  static const int _fallbackSize = 0x400;

  /// Interface name prefixes of mobile data connections on Android and iOS
  static const _cellularInterfaces = ['rmnet', 'ccmni', 'pdp_ip', 'v4-'];

  final HttpClient httpClient;
  final ConnectionProbe connectionProbe;
  final ErrorLogger _errorLogger;
  final LocalAddressesProvider _localAddresses;

  /// Time limit for the whole /ack exchange with one host
  final Duration _ackTimeout;

  NetworkDiscoveryImpl({
    required int port,
    required this.connectionProbe,
    required this.httpClient,
    required this._errorLogger,
    this._localAddresses = _listLocalAddresses,
    this._ackTimeout = const Duration(seconds: 2),
  }) : super(port);

  @override
  Stream<RemoteHost> scanHosts() async* {
    // How many sockets may be opened in parallel
    const windowSize = 16;

    List<InternetAddress> localAddresses;
    try {
      localAddresses = await _localAddresses();
    } catch (_) {
      localAddresses = const [];
    }
    final candidates = candidateAddresses(localAddresses);

    for (var i = 0; i < candidates.length; i += windowSize) {
      final window = candidates.skip(i).take(windowSize);

      // Wait for all futures to complete
      final hosts = await Future.wait(window.map(_ping));

      // Yield all tested hosts
      yield* Stream.fromIterable(hosts.whereType<RemoteHost>());
    }
  }

  /// Returns the addresses to probe: every host of the /24 subnet of each
  /// private address in [localAddresses], except those addresses themselves.
  /// Falls back to 192.168.0.0 - 192.168.3.255 when none of them is private.
  static List<InternetAddress> candidateAddresses(
    Iterable<InternetAddress> localAddresses,
  ) {
    final ownIPs = <int>{};
    final subnets = <int>{};

    for (final address in localAddresses) {
      if (address.type != InternetAddressType.IPv4) {
        continue;
      }
      final ip = _toInt(address.rawAddress);
      if (_isPrivate(ip)) {
        ownIPs.add(ip);
        subnets.add(ip & 0xFFFFFF00);
      }
    }

    if (subnets.isEmpty) {
      return [
        for (var offset = 0; offset < _fallbackSize; offset++)
          _fromInt(_fallbackBaseIP + offset),
      ];
    }

    return [
      for (final subnet in subnets)
        for (var host = 1; host < 255; host++)
          if (!ownIPs.contains(subnet + host)) _fromInt(subnet + host),
    ];
  }

  static Future<List<InternetAddress>> _listLocalAddresses() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
    );
    return [
      for (final interface in interfaces)
        if (!_cellularInterfaces.any(interface.name.startsWith))
          ...interface.addresses,
    ];
  }

  /// 10.0.0.0/8, 172.16.0.0/12 and 192.168.0.0/16
  static bool _isPrivate(int ip) =>
      (ip & 0xFF000000) == 0x0A000000 ||
      (ip & 0xFFF00000) == 0xAC100000 ||
      (ip & 0xFFFF0000) == 0xC0A80000;

  static int _toInt(Uint8List raw) =>
      (raw[0] << 24) | (raw[1] << 16) | (raw[2] << 8) | raw[3];

  static InternetAddress _fromInt(int ip) => InternetAddress.fromRawAddress(
    Uint8List.fromList([
      (ip >> 24) & 0xFF,
      (ip >> 16) & 0xFF,
      (ip >> 8) & 0xFF,
      ip & 0xFF,
    ]),
    type: InternetAddressType.IPv4,
  );

  Future<RemoteHost?> _ping(InternetAddress address) async {
    try {
      if (!await connectionProbe.testConnection(address)) {
        return null;
      }
      final uri = Uri.parse('http://${address.host}:$port/ack');
      final opening = httpClient.getUrl(uri);
      try {
        return await _testServer(uri, opening).timeout(_ackTimeout);
      } on TimeoutException {
        // Do not keep the connection open while waiting for the response
        // headers. abort() has no effect once they have arrived.
        opening.then((request) => request.abort(), onError: (_) {});
        return null;
      }
    } catch (_) {
      // Not an LPS server, or it stopped while being tested: skip the address
      return null;
    }
  }

  Future<RemoteHost?> _testServer(
    Uri uri,
    Future<HttpClientRequest> opening,
  ) async {
    final request = await opening;
    final resp = await request.close();

    // The body is UTF-8 and may arrive in several chunks
    final message = await resp
        .transform(const Utf8Decoder(allowMalformed: true))
        .join();
    if (resp.statusCode != 200) {
      // Some error
      _errorLogger.log(
        'Server is up on address $uri, '
        'but returns code ${resp.statusCode}. Body: $message',
      );
      return null;
    }

    final data = jsonDecode(message);

    return RemoteHost(
      address: uri.host,
      hostName: data['hostName'] ?? 'Unknown',
      versionName: data['version'] ?? '???',
      buildNumber: data['build'] ?? 0,
    );
  }

  @override
  void close() => httpClient.close();
}
