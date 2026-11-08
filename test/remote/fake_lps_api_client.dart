import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/client/api_client.dart';
import 'package:lets_play_cities/remote/model/blacklist_item_info.dart';
import 'package:lets_play_cities/remote/model/friend_info.dart';
import 'package:lets_play_cities/remote/model/friend_request_type.dart';
import 'package:lets_play_cities/remote/model/history_info.dart';

/// In-memory [LpsApiClient] that records calls.
class FakeLpsApiClient extends Fake implements LpsApiClient {
  List<FriendInfo> friends = [];
  List<BlackListItemInfo> banList = [];

  /// Result of [signUp]; when it returns an error the call fails with it.
  Future<RemoteSignUpResponse> Function(RemoteSignUpData data) onSignUp = (_) =>
      Future.error(StateError('signUp is not configured'));

  /// Result of [getProfileInfo]; when it throws the call fails with it.
  ProfileInfo Function(int targetId) onGetProfileInfo = profile;

  int friendsListCalls = 0;
  int banListCalls = 0;
  int signUpCalls = 0;
  final profileInfoCalls = <int>[];

  @override
  Future<List<FriendInfo>> getFriendsList() async {
    friendsListCalls++;
    return [...friends];
  }

  @override
  Future<List<BlackListItemInfo>> getBanList() async {
    banListCalls++;
    return [...banList];
  }

  @override
  Future<ProfileInfo> getProfileInfo(int targetId) async {
    profileInfoCalls.add(targetId);
    return onGetProfileInfo(targetId);
  }

  @override
  Future<RemoteSignUpResponse> signUp(RemoteSignUpData data) {
    signUpCalls++;
    return onSignUp(data);
  }

  @override
  Future<List<HistoryInfo>> getHistoryList([int? targetId]) async => [];

  @override
  Future deleteFriend(int friendId) async {}

  @override
  Future sendFriendRequest(int friendId, FriendRequestType requestType) async {}

  @override
  Future addToBanlist(int userId) async {}

  @override
  Future removeFromBanlist(int userId) async {}
}

ProfileInfo profile(
  int userId, {
  String login = 'user',
  FriendshipStatus friendshipStatus = FriendshipStatus.notFriends,
}) => ProfileInfo(
  userId: userId,
  login: login,
  pictureUrl: null,
  role: Role.regular,
  lastVisitDate: DateTime(2020),
  banStatus: BanStatus.notBanned,
  friendshipStatus: friendshipStatus,
  authType: AuthType.native,
);

final _appConfig = AppConfig.forHost('test');

FriendInfo friend(int userId) => FriendInfo.fromJson(_appConfig, {
  'userId': userId,
  'login': 'friend$userId',
  'accepted': true,
  'sender': false,
  'pictureHash': null,
});

BlackListItemInfo banned(int userId) => BlackListItemInfo.fromJson(_appConfig, {
  'userId': userId,
  'login': 'banned$userId',
  'pictureHash': null,
});

RemoteSignUpResponse signUpResponse(int userId, {String login = 'user'}) =>
    RemoteSignUpResponse(
      userId: userId,
      login: login,
      accessToken: 'token$userId',
      pictureHash: '',
      role: Role.regular,
      authType: AuthType.native,
    );
