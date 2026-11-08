import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:lets_play_cities/base/data/picture_source.dart';

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
        'Basic ${base64Encode(utf8.encode("$userId:$accessToken"))}',
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
class LocalAccountInfo extends ClientAccountInfo with Equatable {
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
