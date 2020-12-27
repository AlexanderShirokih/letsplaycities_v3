import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import 'package:lets_play_cities/remote/api_repository.dart';
import 'package:lets_play_cities/remote/remote_module.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/base/data.dart';

/// Contains user credentials, which is the result of server authorization.
class Credential extends Equatable {
  /// Unique user ID.
  /// Used to uniquely identify user on the game server.
  final int userId;

  /// Access token is used to authenticate user on the server.
  final String accessToken;

  const Credential({@required this.userId, @required this.accessToken})
      : assert(userId != null),
        assert(accessToken != null);

  @override
  List<Object> get props => [userId, accessToken];

  Map<String, String> asAuthorizationHeader() => {
        'authorization':
            'Basic ${base64Encode(utf8.encode("$userId:$accessToken"))}'
      };
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

  const LocalAccountInfo({@required this.name, @required this.picture})
      : assert(name != null),
        assert(picture != null);

  @override
  final String name;

  @override
  bool get canReceiveMessages => false;

  @override
  List<Object> get props => [name, picture];
}

/// Contains remote account info of the user
class RemoteAccount extends ClientAccountInfo with EquatableMixin {
  /// User credentials
  final Credential credential;

  RemoteAccount({
    @required this.credential,
    @required this.name,
    @required this.canReceiveMessages,
    @required String pictureUri,
  })  : picture = NetworkPictureSource(pictureUri),
        assert(credential != null),
        assert(name != null);

  @override
  final String name;

  @override
  final PictureSource picture;

  @override
  final bool canReceiveMessages;

  @override
  List<Object> get props => [credential, name, picture];

  /// Creates [ApiRepository] for this account
  ApiRepository getApiRepository() => ApiRepository(
        RemoteLpsApiClient(
          getDio(),
          credential,
        ),
      );
}

/// Used when some authorization error happened
class AuthorizationException implements Exception {
  final String message;

  AuthorizationException(this.message) : assert(message != null);

  factory AuthorizationException.fromStatus(
          String reasonPhrase, int responseCode) =>
      AuthorizationException('Status: $responseCode ($reasonPhrase)');

  @override
  String toString() => 'Authorization error: $message';
}

/// Used when error happens during API fetch requests
class FetchingException implements Exception {
  final String message;
  final Uri uri;

  FetchingException(this.message, this.uri) : assert(message != null);

  @override
  String toString() => 'Fetching exception: $message, URL: $uri';
}
