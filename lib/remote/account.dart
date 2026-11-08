import 'package:equatable/equatable.dart';
import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/remote/auth.dart';

export 'package:lets_play_cities/base/data/account_info.dart';

abstract class CredentialsProvider {
  Credential getCredentials();
}

/// Credentials provider that takes credentials from the instance
class InstancedCredentialsProvider implements CredentialsProvider {
  final Credential _credential;

  const InstancedCredentialsProvider(this._credential);

  @override
  Credential getCredentials() => _credential;
}

/// Credentials provider that takes credentials from the preferences
class GamePreferencesCredentialsProvider implements CredentialsProvider {
  final GamePreferences _gamePreferences;

  GamePreferencesCredentialsProvider(this._gamePreferences);

  @override
  Credential getCredentials() {
    return _gamePreferences.currentCredentials ?? Credential.empty();
  }
}

/// [ClientAccountInfo] constructed from [ProfileInfo]
class AdvancedAccountInfo extends ClientAccountInfo with Equatable {
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
class RemoteAccount extends ClientAccountInfo with Equatable {
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
}
