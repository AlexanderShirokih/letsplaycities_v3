import 'dart:io';

import 'package:flutter/services.dart';

/// Helper bridge to native code that handles some network related utilities
/// functions
class NetworkManager {
  static const MethodChannel _prefsMigrationChannel =
      MethodChannel('ru.aleshi.letsplaycities/network_utils');

  /// Checks that wi-fi is enabled and user connected to the right network.
  static Future<bool> ensureWifiConnected() async {
    if (Platform.isAndroid) {
      return await _prefsMigrationChannel.invokeMethod('ensureWifiConnected');
    }
    return true;
  }
}
