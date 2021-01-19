import 'dart:io';

import 'package:flutter/services.dart';

/// Helper bridge to native code that handles some network related utilities
/// functions
class NetworkManager {
  static const MethodChannel _prefsMigrationChannel =
      MethodChannel('ru.aleshi.letsplaycities/network_utils');

  /// Starts Wi-Fi hotspot activity on Android, if available.
  /// Returns `true` if hotspot already running
  static Future<bool> unsureHotspotEnabled() async {
    if (Platform.isAndroid) {
      // TODO: Implement android plugin!. Source: ui/remote/MultiplayerFragment.kt
      return await _prefsMigrationChannel.invokeMethod('unsureHotspotEnabled');
    }
    return true;
  }

  /// Checks that wi-fi is enabled and user connected to the right network.
  static Future<bool> unsureWifiConnected() async {
    if (Platform.isAndroid) {
      // TODO: Implement android plugin!. Source: ui/remote/MultiplayerFragment.kt
      return await _prefsMigrationChannel.invokeMethod('unsureWifiConnected');
    }
    return true;
  }
}
