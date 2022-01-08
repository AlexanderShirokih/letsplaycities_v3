import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/remote/auth.dart';

/// Contains user credentials, which is the result of server authorization.
class Credential extends Equatable {
  /// Unique user ID.
  /// Used to uniquely identify user on the game server.
  final int userId;

  /// Access token is used to authenticate user on the server.
  final String accessToken;

  const Credential({required this.userId, required this.accessToken});

  const Credential.empty() : this(userId: 0, accessToken: '');

  @override
  List<Object> get props => [userId, accessToken];

  Map<String, String> asAuthorizationHeader() => {
        'authorization':
            'Basic ${base64Encode(utf8.encode("$userId:$accessToken"))}'
      };
}

/// Default credentials provider
class CredentialsProvider {
  final GamePreferences _gamePreferences;

  CredentialsProvider(this._gamePreferences);

  Credential getCredentials() {
    return _gamePreferences.currentCredentials ?? Credential.empty();
  }
}

/// Contains authorization data
abstract class ClientAccountInfo {
  /// User name
  String get name;

  /// Profile picture URI
  PictureSource get picture;

  /// `True` is the user wants receive messages from the other users.
  bool get canReceiveMessages;

  const ClientAccountInfo();
}

/// [ClientAccountInfo] for local users
class LocalAccountInfo extends ClientAccountInfo with EquatableMixin {
  @override
  final PictureSource picture;

  const LocalAccountInfo({required this.name, required this.picture});

  @override
  final String name;

  @override
  bool get canReceiveMessages => false;

  @override
  List<Object> get props => [name, picture];
}

/// [ClientAccountInfo] constructed from [ProfileInfo]
class AdvancedAccountInfo extends ClientAccountInfo with EquatableMixin {
  final ProfileInfo profileInfo;

  @override
  final bool canReceiveMessages;

  AdvancedAccountInfo(this.profileInfo, this.canReceiveMessages);

  @override
  String get name => profileInfo.login;

  @override
  PictureSource get picture => NetworkPictureSource(profileInfo.pictureUrl);

  @override
  List<Object> get props => [name, picture];
}

/// Contains remote account info of the user
class RemoteAccount extends ClientAccountInfo with EquatableMixin {
  /// User credentials
  final Credential credential;

  /// Users role on server
  final Role role;

  /// Account origin
  final AuthType authType;

  RemoteAccount({
    required this.credential,
    required this.name,
    required this.canReceiveMessages,
    required this.role,
    required this.authType,
    required String? pictureUri,
  }) : picture = NetworkPictureSource(pictureUri);

  @override
  final String name;

  @override
  final PictureSource picture;

  @override
  final bool canReceiveMessages;

  @override
  List<Object> get props => [credential, name, picture];

  /// Returns [BaseProfileInfo] for this account
  BaseProfileInfo get baseProfileInfo => BaseProfileInfo(
        userId: credential.userId,
        login: name,
        pictureUrl: (picture as NetworkPictureSource).pictureURL,
      );

  /// Creates [ApiRepository] for this account
  ApiRepository getApiRepository() =>
      GetIt.instance.get<ApiRepository>(param1: credential);
}
