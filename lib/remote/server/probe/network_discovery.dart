import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/base/data/app_version.dart';
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
  }) =>
      NetworkDiscoveryImpl(
        port: port,
        connectionProbe: ConnectionProbeImpl(port, timeout),
        httpClient: HttpClient(),
      );
}

class NetworkDiscoveryImpl extends NetworkDiscovery {
  static const int _baseIP = 0xC0A80000;
  static const int _wildCard = 0x000003FF;

  final HttpClient httpClient;
  final ConnectionProbe connectionProbe;

  NetworkDiscoveryImpl({
    required int port,
    required this.connectionProbe,
    required this.httpClient,
  }) : super(port);

  @override
  Stream<RemoteHost> scanHosts() async* {
    // How many sockets may be opened in parallel
    const windowSize = 16;

    final addresses = List<Uint8List>.generate(
      windowSize,
      (_) => Uint8List(4)
        ..[0] = 192
        ..[1] = 168,
    );

    Uint8List buildAddress(int addressSlot, int offset) {
      final ip = _baseIP + offset;
      final address = addresses[addressSlot];
      address[2] = (ip & 0xFF00) >> 8;
      address[3] = ip & 0xFF;
      return address;
    }

    // Go through all subnet
    for (var i = 0; i < _wildCard; i += windowSize) {
      final futures = List.generate(
        windowSize,
        (index) => InternetAddress.fromRawAddress(
          buildAddress(index, index + i),
          type: InternetAddressType.IPv4,
        ),
      ).map(_ping);

      // Wait for all futures to complete
      final hosts = await Future.wait<RemoteHost?>(futures);

      // Yield all tested hosts
      yield* Stream.fromIterable(
        hosts.where((element) => element != null).cast<RemoteHost>(),
      );
    }
  }

  Future<RemoteHost?> _ping(InternetAddress address) async {
    final isAvailable = await connectionProbe.testConnection(address);

    if (isAvailable) {
      return await _testServer(address.host);
    }

    return null;
  }

  Future<RemoteHost?> _testServer(String host) async {
    final uri = Uri.parse('http://$host:$port/ack');

    final result = await httpClient.getUrl(uri);

    try {
      final resp = await result.close().timeout(Duration(seconds: 1));

      final message = String.fromCharCodes(await resp.first);
      if (resp.statusCode != 200) {
        // Some error
        GetIt.instance<ErrorLogger>().log('Server is up on address ${uri}, '
            'but returns code ${resp.statusCode}. Body: ${message}');
        return null;
      }

      final data = jsonDecode(message);

      return RemoteHost(
        address: uri.host,
        hostName: data['hostName'] ?? 'Unknown',
        version: VersionInfo(
          data['version'] ?? '???',
          data['build'] ?? 0,
        ),
      );
    } on TimeoutException {
      // Assume server is not running on this address
      return null;
    } on SocketException {
      return null;
    }
  }

  @override
  void close() => httpClient.close();
}
