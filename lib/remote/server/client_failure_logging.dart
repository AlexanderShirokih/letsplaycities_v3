import 'dart:async';
import 'dart:io';

import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:lets_play_cities/utils/error_logger.dart';

/// Whether [error] is a failure that a LAN client causes on its own:
/// - during the handshake, it stays silent ([TimeoutException]) or drops the
///   connection ([ClientDisconnectedException]);
/// - in a request, it opens `/game` in a browser, which fails the WebSocket
///   upgrade ([WebSocketException]), drops the connection while the server
///   reads the request ([HttpException]), or sends a malformed body
///   ([FormatException]).
bool isClientFailure(Object error) =>
    error is TimeoutException ||
    error is ClientDisconnectedException ||
    error is WebSocketException ||
    error is HttpException ||
    error is FormatException;

extension ClientFailureLogging on ErrorLogger {
  /// Logs [failure] as a short message when a client caused it, see
  /// [isClientFailure], and reports anything else as an error.
  void clientFailure(String action, Object failure, StackTrace stackTrace) {
    if (isClientFailure(failure)) {
      log('$action: $failure');
    } else {
      error(failure, stackTrace);
    }
  }
}
