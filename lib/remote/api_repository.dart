import 'dart:typed_data';

// ignore: import_of_legacy_library_into_null_safe
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
import 'package:meta/meta.dart';

class _TargetedList<T> {
  final int targetId;
  final List<T> data;

  const _TargetedList(this.targetId, this.data);
}

/// Factory for creating API repositories
class ApiRepositoryProvider {
  final Map<LpsApiClient, ApiRepository> _cache = {};

  ApiRepository getApiRepository(LpsApiClient lpsApiClient) {
    return _cache.putIfAbsent(
        lpsApiClient, () => ApiRepository._(lpsApiClient));
  }
}

/// Repository class wrapping [LpsApiClient]
class ApiRepository with AvatarResizeMixin {
  static const _kMaxProfilesCacheSize = 12;

  final LpsApiClient _client;
  final CacheList<ProfileInfo> _cachedProfilesInfo =
      CacheList(_kMaxProfilesCacheSize);
  final CacheList<_TargetedList<HistoryInfo>> _cachedHistoriesInfo =
      CacheList(_kMaxProfilesCacheSize);

  List<BlackListItemInfo>? _cachedBanList;
  List<FriendInfo>? _cachedFriendsList;

  @protected
  ApiRepository._(this._client);

  /// Gets user friends list.
  /// Network request will used only first time or when [forceRefresh] is `true`
  /// in all the other cases cached instance of friends list will be used.
  Future<List<FriendInfo>> getFriendsList(bool forceRefresh) async {
    if (_cachedFriendsList == null || forceRefresh) {
      _cachedFriendsList = await _client.getFriendsList();
    }
    return _cachedFriendsList!;
  }

  void _invalidateFriendsList() {
    _cachedFriendsList = null;
  }

  /// Deletes friend from friend list.
  Future deleteFriend(BaseProfileInfo friend) => _client
      .deleteFriend(friend.userId)
      .then((_) => _cachedFriendsList?.remove(friend));

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
      .then((_) => _cachedProfilesInfo.remove(target as ProfileInfo));

  /// Gets user battle history.
  /// Network request will used only first time or when [forceRefresh] is `true`
  /// in all the other cases cached instance of history list will be used.
  Future<List<HistoryInfo>> getHistoryList(
      bool forceRefresh, BaseProfileInfo target) async {
    final predicate = (_TargetedList<HistoryInfo> element) =>
        element.targetId == target.userId;

    if (forceRefresh) {
      _cachedHistoriesInfo.removeWhere(predicate);
    }

    var battleHistory = await _cachedHistoriesInfo.getOrFetch(
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
    if (_cachedBanList == null || forceRefresh) {
      _cachedBanList = await _client.getBanList();
    }
    return _cachedBanList!;
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
      _cachedProfilesInfo.removeWhere(predicate);
    }

    return await _cachedProfilesInfo.getOrFetch(
        predicate, () => _client.getProfileInfo(target.userId));
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
