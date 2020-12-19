import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:lets_play_cities/remote/model/friend_request_type.dart';
import 'package:lets_play_cities/remote/model/profile_info.dart';
import 'package:meta/meta.dart';

import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/model/blacklist_item_info.dart';
import 'package:lets_play_cities/remote/model/friend_info.dart';
import 'package:lets_play_cities/remote/model/history_info.dart';
import 'package:lets_play_cities/base/data.dart';

/// LPS remote service client
abstract class LpsApiClient {
  /// Sends sign up request and returns [ClientAccountInfo] containing user data
  /// or throws [AuthorizationException] if cannot sign up on server by any reason.
  Future<ClientAccountInfo> signUp(RemoteSignInData data);

  /// Queries friends list from server. Throws an exception if cannot fetch data.
  Future<List<FriendInfo>> getFriendsList();

  /// Queries ban list from server. Throws an exception if cannot fetch data.
  Future<List<BlackListItemInfo>> getBanList();

  /// Queries battle history list from server. Throws an exception if cannot
  /// fetch data. If [targetId] passes common history of signed in user and
  /// target user will shown.
  Future<List<HistoryInfo>> getHistoryList([int targetId]);

  /// Deletes a user with id [friendId] from user's friend list
  Future deleteFriend(int friendId);

  /// Sends a friendship request
  Future sendFriendRequest(int friendId, FriendRequestType requestType);

  /// Removes a user with [userId] from players ban list
  Future removeFromBanlist(int userId);

  /// Adds a user with [userId] to players ban list
  Future addToBanlist(int userId);

  /// Fetches information about user profile
  /// If [targetId] is passed profile info about that user will be fetched.
  /// If [targetId] is null info about current user will be fetched
  Future<ProfileInfo> getProfileInfo(int targetId);

  const LpsApiClient();
}

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
class RemoteAccountInfo extends ClientAccountInfo with EquatableMixin {
  /// User credentials
  final Credential credential;

  RemoteAccountInfo({
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

  FetchingException(this.message) : assert(message != null);

  @override
  String toString() => 'Fetching exception: $message';
}
