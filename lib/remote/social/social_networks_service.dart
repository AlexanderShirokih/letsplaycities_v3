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
}
