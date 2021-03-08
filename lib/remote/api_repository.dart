import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/base/remote/bloc/avatar_resize_mixin.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/client/api_client.dart';
import 'package:lets_play_cities/remote/model/blacklist_item_info.dart';
import 'package:lets_play_cities/remote/model/friend_info.dart';
import 'package:lets_play_cities/remote/model/friend_request_type.dart';
import 'package:lets_play_cities/remote/model/history_info.dart';
import 'package:lets_play_cities/remote/model/profile_info.dart';
import 'package:lets_play_cities/utils/cache_list.dart';

class _TargetedList<T> {
  final int targetId;
  final List<T> data;

  const _TargetedList(this.targetId, this.data);
}

class ApiRepositoryCacheHolder {
  static const _kMaxProfilesCacheSize = 12;

  final CacheList<ProfileInfo> cachedProfilesInfo =
      CacheList(_kMaxProfilesCacheSize);
  final CacheList<_TargetedList<HistoryInfo>> cachedHistoriesInfo =
      CacheList(_kMaxProfilesCacheSize);

  List<BlackListItemInfo>? cachedBanList;
  List<FriendInfo>? cachedFriendsList;
}

/// Repository class wrapping [LpsApiClient]
class ApiRepository with AvatarResizeMixin {
  final LpsApiClient _client;

  final ApiRepositoryCacheHolder _cache;

  ApiRepository(this._client, this._cache);

  /// Gets user friends list.
  /// Network request will used only first time or when [forceRefresh] is `true`
  /// in all the other cases cached instance of friends list will be used.
  Future<List<FriendInfo>> getFriendsList(bool forceRefresh) async {
    if (_cache.cachedFriendsList == null || forceRefresh) {
      _cache.cachedFriendsList = await _client.getFriendsList();
    }
    return _cache.cachedFriendsList!;
  }

  void _invalidateFriendsList() {
    _cache.cachedFriendsList = null;
  }

  /// Deletes friend from friend list.
  Future deleteFriend(BaseProfileInfo friend) => _client
      .deleteFriend(friend.userId)
      .then((_) => _cache.cachedFriendsList?.remove(friend));

  /// Sends negative result to the game request sent by [requester]
  Future<void> declineGameRequest(BaseProfileInfo requester) =>
      _client.declineGameRequest(requester.userId);

  /// Accepts or denies input friendship request from user [friendId]
  Future sendFriendRequestAcceptance(BaseProfileInfo friend, bool isAccepted) =>
      _client
          .sendFriendRequest(
            friend.userId,
            isAccepted ? FriendRequestType.ACCEPT : FriendRequestType.DENY,
          )
          .then((_) => _invalidateFriendsList());

  /// Sends new friendship request
  Future sendNewFriendshipRequest(BaseProfileInfo target) => _client
      .sendFriendRequest(target.userId, FriendRequestType.SEND)
      .then((_) => _cache.cachedProfilesInfo.remove(target as ProfileInfo));

  /// Gets user battle history.
  /// Network request will used only first time or when [forceRefresh] is `true`
  /// in all the other cases cached instance of history list will be used.
  Future<List<HistoryInfo>> getHistoryList(
      bool forceRefresh, BaseProfileInfo target) async {
    final predicate = (_TargetedList<HistoryInfo> element) =>
        element.targetId == target.userId;

    if (forceRefresh) {
      _cache.cachedHistoriesInfo.removeWhere(predicate);
    }

    var battleHistory = await _cache.cachedHistoriesInfo.getOrFetch(
        predicate,
        () async => _TargetedList(
              target.userId,
              await _client.getHistoryList(target.userId),
            ));

    return battleHistory.data;
  }

  /// Gets user which was blocked by player.
  /// Network request will used only first time or when [forceRefresh] is `true`
  /// in all the other cases cached instance of blocked users list will be used.
  Future<List<BlackListItemInfo>> getBanlist(bool forceRefresh) async {
    if (_cache.cachedBanList == null || forceRefresh) {
      _cache.cachedBanList = await _client.getBanList();
    }
    return _cache.cachedBanList!;
  }

  /// Removes a user with [user] from players ban list
  Future removeFromBanlist(BaseProfileInfo user) =>
      _client.removeFromBanlist(user.userId);

  /// Adds a user with [user] to players ban list
  Future addToBanlist(BaseProfileInfo user) =>
      _client.addToBanlist(user.userId);

  /// Fetches information about user profile
  /// If [target] is passed profile info about that user will be fetched.
  /// If [target] is `null` info about current user will be fetched
  /// Network request will used either on first time or when [forceRefresh] is
  /// `true` in all the other cases cached instance of profile info list will
  /// be used.
  Future<ProfileInfo> getProfileInfo(BaseProfileInfo target,
      [bool forceRefresh = false]) async {
    final predicate = (element) => element.userId == target.userId;

    if (forceRefresh) {
      _cache.cachedProfilesInfo.removeWhere(predicate);
    }

    return await _cache.cachedProfilesInfo
        .getOrFetch(predicate, () => _client.getProfileInfo(target.userId));
  }

  /// First fetches picture from [pictureURL] and updates picture on server
  Future<void> updatePictureFromURL(String pictureURL) {
    final picture = GetIt.instance.get<Dio>().get(
          pictureURL,
          options: Options(responseType: ResponseType.bytes),
        );

    return updatePicture(picture.then((resp) => resp.data));
  }

  /// Updates picture for currently logged account
  Future<void> updatePicture(Future<Uint8List> imageData) async {
    final thumbnail = await createThumbnail(await imageData);
    await _client.updatePicture(thumbnail, 'image/png');
  }

  /// Removes user picture from currently logged account
  Future<void> removePicture() => _client.removePicture();
}
