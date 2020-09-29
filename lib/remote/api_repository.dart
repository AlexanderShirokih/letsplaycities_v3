import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/model/friend_info.dart';
import 'package:lets_play_cities/remote/model/history_info.dart';
import 'package:lets_play_cities/remote/model/friend_request_type.dart';
import 'package:lets_play_cities/remote/model/blacklist_item_info.dart';
import 'package:lets_play_cities/remote/model/profile_info.dart';

/// Repository class wrapping [LpsApiClient]
class ApiRepository {
  final LpsApiClient _client;

  List<BlackListItemInfo> _cachedBanList;
  List<HistoryInfo> _cachedHistoryList;
  List<FriendInfo> _cachedFriendsList;
  ProfileInfo _cachedProfileInfo;

  ApiRepository(this._client);

  /// Gets user friends list.
  /// Network request will used only first time or when [forceRefresh] is `true`
  /// in all the other cases cached instance of friends list will be used.
  Future<List<FriendInfo>> getFriendsList(bool forceRefresh) async {
    if (_cachedFriendsList == null || forceRefresh) {
      _cachedFriendsList = await _client.getFriendsList();
    }
    return _cachedFriendsList;
  }

  /// Deletes friend from friend list.
  Future deleteFriend(int friendId) => _client.deleteFriend(friendId);

  /// Accepts or denies input friendship request from user [friendId]
  Future sendFriendRequestAcceptance(int friendId, bool isAccepted) =>
      _client.sendFriendRequest(
        friendId,
        isAccepted ? FriendRequestType.ACCEPT : FriendRequestType.DENY,
      );

  /// Sends new friendship request
  Future sendNewFriendshipRequest(int targetId) =>
      _client.sendFriendRequest(targetId, FriendRequestType.SEND);

  /// Gets user battle history.
  /// Network request will used only first time or when [forceRefresh] is `true`
  /// in all the other cases cached instance of history list will be used.
  Future<List<HistoryInfo>> getHistoryList(bool forceRefresh) async {
    if (_cachedHistoryList == null || forceRefresh) {
      _cachedHistoryList = await _client.getHistoryList();
    }
    return _cachedHistoryList;
  }

  /// Gets user which was blocked by player.
  /// Network request will used only first time or when [forceRefresh] is `true`
  /// in all the other cases cached instance of blocked users list will be used.
  Future<List<BlackListItemInfo>> getBanlist(bool forceRefresh) async {
    if (_cachedBanList == null || forceRefresh) {
      _cachedBanList = await _client.getBanList();
    }
    return _cachedBanList;
  }

  /// Removes a user with [userId] from players ban list
  Future removeFromBanlist(int userId) => _client.removeFromBanlist(userId);

  /// Adds a user with [userId] to players ban list
  Future addToBanlist(int userId) => _client.addToBanlist(userId);

  /// Fetches information about user profile
  /// If [targetId] is passed profile info about that user will be fetched.
  /// If [targetId] is null info about current user will be fetched
  /// Network request will used either on first time or when [forceRefresh] is
  /// `true` in all the other cases cached instance of profile info list will
  /// be used.
  Future<ProfileInfo> getProfileInfo(int targetId, bool forceRefresh) async {
    if (_cachedProfileInfo == null || forceRefresh) {
      _cachedProfileInfo = await _client.getProfileInfo(targetId);
    }
    return _cachedProfileInfo;
  }

}
