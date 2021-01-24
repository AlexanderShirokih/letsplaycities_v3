import 'package:lets_play_cities/remote/model/auth_type.dart';

/// Data class describing social network authorization result
class SocialNetworkData {
  /// User name
  final String login;

  /// Social network type
  final AuthType authType;

  /// Social network access token
  final String accessToken;

  /// Social network user ID
  final String snUID;

  final String pictureUri;

  SocialNetworkData({
    required this.login,
    required this.authType,
    required this.pictureUri,
    required this.accessToken,
    required this.snUID,
  });

  factory SocialNetworkData.fromJson(Map<String, dynamic> json) =>
      SocialNetworkData(
        login: json['login'],
        authType: AuthTypeExtension.fromString(json['networkType']),
        pictureUri: json['pictureUri'],
        accessToken: json['accessToken'],
        snUID: json['snUID'],
      );
}
