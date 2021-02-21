import 'dart:io';

import 'package:device_info/device_info.dart';

/// Provides information about device name
class DeviceNameService {
  /// Contains device brand and model
  final String deviceName;

  DeviceNameService._(this.deviceName);

  static DeviceNameService? _instance;

  static DeviceNameService get instance {
    if (_instance == null) {
      throw 'DeviceNameService is not initialized';
    }
    return _instance!;
  }

  static Future<DeviceNameService> initInstance() async {
    _instance = await _fetchDeviceInfo();
    return _instance!;
  }

  static Future<DeviceNameService> _fetchDeviceInfo() async {
    var deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return DeviceNameService._('${androidInfo.brand} ${androidInfo.model}');
    } else if (Platform.isIOS) {
      final iOSInfo = await deviceInfo.iosInfo;
      return DeviceNameService._('${iOSInfo.name} ${iOSInfo.systemName}');
    } else if (Platform.isFuchsia) {
      return DeviceNameService._("It's Fuchsia!");
    } else {
      return DeviceNameService._('Desktop');
    }
  }
}
