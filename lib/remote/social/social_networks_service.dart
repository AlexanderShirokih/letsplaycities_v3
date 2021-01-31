import 'dart:io';

import 'package:flutter/services.dart';
import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:lets_play_cities/remote/model/auth_type.dart';
import 'package:lets_play_cities/remote/social/social_network_data.dart';

/// Provides access to social networks
abstract class SocialNetworksService {
  /// Starts login process.
  /// Returns social network data if authorization was successful or throws
  /// [AuthorizationException]
  /// error if authorization was cancelled or some error happened
  Future<SocialNetworkData> login(AuthType networkType);

  /// Starts logout process for previously logged in social network.
  Future<void> logout(AuthType networkType);

  /// Returns static identifier for this device.
  Future<String> getDeviceId();
}

/// [SocialNetworksService] implementation that uses native channels
/// to provide social network authorization
class NativeBridgeSocialNetworksService implements SocialNetworksService {
  static const MethodChannel _authenticationChannel =
      MethodChannel('ru.aleshi.letsplaycities/authentication');

  @override
  Future<SocialNetworkData> login(AuthType networkType) async {
    try {
      final result = await _authenticationChannel
          .invokeMapMethod<String, dynamic>(
              'login', {'authType': networkType.name});
      return SocialNetworkData.fromJson(result!);
    } on PlatformException catch (e) {
      throw AuthorizationException('${e.code}: ${e.message}');
    }
  }

  @override
  Future<void> logout(AuthType networkType) {
    return _authenticationChannel.invokeMapMethod<String, dynamic>(
        'logout', {'authType': networkType.name});
  }

  @override
  Future<String> getDeviceId() async {
    try {
      return await _authenticationChannel.invokeMethod('getDeviceId');
    } on PlatformException {
      if (!Platform.isLinux) {
        return 'linuz-test';
      } else {
        rethrow;
      }
    }
  }
}
