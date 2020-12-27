import 'dart:collection';
import 'dart:typed_data';

import 'package:lets_play_cities/base/remote/bloc/avatar_resize_mixin.dart';
import 'package:lets_play_cities/remote/api_client.dart';
import 'package:lets_play_cities/remote/model/blacklist_item_info.dart';
import 'package:lets_play_cities/remote/model/friend_info.dart';
import 'package:lets_play_cities/remote/model/friend_request_type.dart';
import 'package:lets_play_cities/remote/model/history_info.dart';
import 'package:lets_play_cities/remote/model/profile_info.dart';

class _TargetedList<T> {
  final int targetId;
  final List<T> data;

  const _TargetedList(this.targetId, this.data);
}

/// Repository class wrapping [LpsApiClient]
class ApiRepository with AvatarResizeMixin {
  static const _kMaxProfilesCacheSize = 12;

  final LpsApiClient _client;
  final Queue<ProfileInfo> _cachedProfilesInfo =
      ListQueue(_kMaxProfilesCacheSize);
  final Queue<_TargetedList<HistoryInfo>> _cachedHistoriesInfo =
      ListQueue(_kMaxProfilesCacheSize);

  List<BlackListItemInfo> _cachedBanList;
  List<FriendInfo> _cachedFriendsList;

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
  /// If [targetId] is not `null` common history of logged-in user and [targetId]
  /// will shown.
  Future<List<HistoryInfo>> getHistoryList(bool forceRefresh,
      {int targetId}) async {
    var battleHistory = _cachedHistoriesInfo.singleWhere(
      (element) => element.targetId == targetId,
      orElse: () => null,
    );

    if (battleHistory == null || forceRefresh) {
      if (_cachedHistoriesInfo.length == _kMaxProfilesCacheSize) {
        _cachedHistoriesInfo.removeLast();
      }
      battleHistory = _TargetedList(
        targetId,
        await _client.getHistoryList(targetId),
      );
      _cachedHistoriesInfo.add(battleHistory);
    }
    return battleHistory.data;
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
    var profile = _cachedProfilesInfo.singleWhere(
      (element) => element.userId == targetId,
      orElse: () => null,
    );

    if (profile == null || forceRefresh) {
      if (_cachedProfilesInfo.length == _kMaxProfilesCacheSize) {
        _cachedProfilesInfo.removeLast();
      }
      profile = await _client.getProfileInfo(targetId);
      _cachedProfilesInfo.add(profile);
    }
    return profile;
  }

  /// Updates picture for currently logged account
  Future<void> updatePicture(Future<Uint8List> imageData) async {
    final thumbnail = await createThumbnail(await imageData);
    await _client.updatePicture(thumbnail, 'image/png');
  }

  /// Removes user picture from currently logged account
  Future<void> removePicture() => _client.removePicture();
}
