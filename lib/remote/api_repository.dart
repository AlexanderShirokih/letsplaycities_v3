import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/remote/client/social_api.dart';
import 'package:lets_play_cities/remote/model/lps_user.dart';
import 'package:lets_play_cities/remote/model/social.dart';
import 'package:lets_play_cities/utils/avatar_resize_mixin.dart';
import 'package:lets_play_cities/utils/cache_list.dart';

/// The first page of the history of the games with [withUser], `null` for
/// the games with everybody
class CachedHistory {
  final int? withUser;
  final HistoryPage firstPage;

  const CachedHistory(this.withUser, this.firstPage);
}

class ApiRepositoryCacheHolder {
  static const _kMaxProfilesCacheSize = 12;

  final CacheList<UserProfile> cachedProfiles = CacheList(
    _kMaxProfilesCacheSize,
  );
  final CacheList<CachedHistory> cachedHistories = CacheList(
    _kMaxProfilesCacheSize,
  );

  List<LpsUser>? cachedBlocks;
  List<FriendEntry>? cachedFriends;

  /// Drops all cached data. Call it when the signed-in account changes: the
  /// lists and the friendship and block statuses belong to one account.
  void clear() {
    cachedProfiles.clear();
    cachedHistories.clear();
    cachedBlocks = null;
    cachedFriends = null;
  }
}

/// Repository class wrapping [SocialApi]
class ApiRepository with AvatarResizeMixin {
  final SocialApi _api;

  final ApiRepositoryCacheHolder _cache;

  /// The server that serves the avatars
  final AppConfig _pictureConfig;

  /// Downloads the picture for [putAvatarFromUrl].
  final Dio _pictureDownloader;

  ApiRepository(
    this._api,
    this._cache,
    this._pictureConfig,
    this._pictureDownloader,
  );

  /// URL of the avatar of [user], `null` if the user has none
  String? avatarUrl(LpsUser user) => user.avatarUrl(_pictureConfig);

  /// Gets the friends and the friend requests.
  /// Network request will used only first time or when [forceRefresh] is `true`
  /// in all the other cases cached instance of the list will be used.
  Future<List<FriendEntry>> friends(bool forceRefresh) async {
    if (_cache.cachedFriends == null || forceRefresh) {
      _cache.cachedFriends = await _api.friends();
    }
    return _cache.cachedFriends!;
  }

  /// Drops the cached profile of [userId]: its friendship and block statuses
  /// change after any friend or block list action.
  void _forgetProfile(int userId) =>
      _cache.cachedProfiles.removeWhere((p) => p.user.id == userId);

  /// Sends a friend request to [userId] or accepts the request of [userId]
  Future<void> putFriend(int userId) => _api.putFriend(userId).then((_) {
    _cache.cachedFriends = null;
    _forgetProfile(userId);
  });

  /// Declines or cancels the request, or removes the friend [userId]
  Future<void> deleteFriend(int userId) => _api.deleteFriend(userId).then((_) {
    _cache.cachedFriends?.removeWhere((f) => f.user.id == userId);
    _forgetProfile(userId);
  });

  /// Gets users which was blocked by player.
  /// Network request will used only first time or when [forceRefresh] is `true`
  /// in all the other cases cached instance of blocked users list will be used.
  Future<List<LpsUser>> blocks(bool forceRefresh) async {
    if (_cache.cachedBlocks == null || forceRefresh) {
      _cache.cachedBlocks = await _api.blocks();
    }
    return _cache.cachedBlocks!;
  }

  /// Blocks [userId]. The server ends their friendship, so the friends list
  /// is dropped too.
  Future<void> putBlock(int userId) => _api.putBlock(userId).then((_) {
    // A block list entry cannot be built from the id, so refetch the list.
    _cache.cachedBlocks = null;
    _cache.cachedFriends = null;
    _forgetProfile(userId);
  });

  Future<void> deleteBlock(int userId) => _api.deleteBlock(userId).then((_) {
    _cache.cachedBlocks?.removeWhere((b) => b.id == userId);
    _forgetProfile(userId);
  });

  /// A page of the history, from the newest game: the games with [withUser]
  /// if it is set, the games with everybody otherwise. The first page
  /// ([before] is `null`) is requested only first time or when
  /// [forceRefresh] is `true`; the next ones follow [HistoryPage.next]
  /// and are not cached.
  Future<HistoryPage> history({
    int? withUser,
    int? before,
    bool forceRefresh = false,
  }) async {
    if (before != null) {
      return _api.history(withUser: withUser, before: before);
    }

    bool predicate(CachedHistory element) => element.withUser == withUser;

    if (forceRefresh) {
      _cache.cachedHistories.removeWhere(predicate);
    }

    final cached = await _cache.cachedHistories.getOrFetch(
      predicate,
      () async =>
          CachedHistory(withUser, await _api.history(withUser: withUser)),
    );

    return cached.firstPage;
  }

  /// Fetches the user [id] with the friendship and the block between the
  /// users.
  /// Network request will used either on first time or when [forceRefresh] is
  /// `true` in all the other cases cached instance will be used.
  Future<UserProfile> user(int id, [bool forceRefresh = false]) async {
    bool predicate(UserProfile element) => element.user.id == id;

    if (forceRefresh) {
      _cache.cachedProfiles.removeWhere(predicate);
    }

    return await _cache.cachedProfiles.getOrFetch(
      predicate,
      () => _api.user(id),
    );
  }

  /// First fetches picture from [pictureURL] and makes it the avatar
  Future<LpsUser> putAvatarFromUrl(String pictureURL) async =>
      putAvatar(await downloadPicture(pictureURL));

  /// Downloads the picture at [pictureURL]
  Future<Uint8List> downloadPicture(String pictureURL) async {
    final picture = await _pictureDownloader.get<List<int>>(
      pictureURL,
      options: Options(responseType: ResponseType.bytes),
    );

    return Uint8List.fromList(picture.data!);
  }

  /// Scales [image] to the size of the avatar and makes it the avatar of
  /// the signed-in user
  Future<LpsUser> putAvatar(Uint8List image) async =>
      _api.putAvatar(await createAvatarPng(image));

  /// Removes the avatar of the signed-in user
  Future<void> deleteAvatar() => _api.deleteAvatar();
}
