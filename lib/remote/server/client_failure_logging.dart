import 'dart:async';
import 'dart:io';

import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:lets_play_cities/utils/error_logger.dart';

/// Whether [error] is a failure that a LAN client causes on its own: it
/// stays silent ([TimeoutException]), drops the connection
/// ([ClientDisconnectedException], [HttpException]), opens `/v1/game` in a
/// browser, which fails the WebSocket upgrade ([WebSocketException]), or
/// sends a malformed message ([FormatException]).
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
