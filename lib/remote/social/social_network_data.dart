import 'package:equatable/equatable.dart';
import 'package:lets_play_cities/remote/model/auth_type.dart';

/// Data class describing social network authorization result
class SocialNetworkData extends Equatable {
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
        authType: AuthTypeExtension.fromShortString(json['networkType']),
        pictureUri: json['pictureUri'],
        accessToken: json['accessToken'],
        snUID: json['snUID'],
      );

  @override
  List<Object?> get props => [login, authType, pictureUri, accessToken, snUID];

  @override
  bool? get stringify => true;
}
