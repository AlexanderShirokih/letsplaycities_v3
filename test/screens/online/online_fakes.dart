import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/model/blacklist_item_info.dart';
import 'package:lets_play_cities/remote/model/friend_info.dart';
import 'package:lets_play_cities/remote/model/history_info.dart';

import '../../i18n/translations_harness.dart';

final _appConfig = AppConfig.forHost('localhost');

FriendInfo friendInfo(
  int userId,
  String login, {
  required bool accepted,
  bool sender = false,
}) => FriendInfo.fromJson(_appConfig, {
  'userId': userId,
  'login': login,
  'accepted': accepted,
  'sender': sender,
});

BlackListItemInfo bannedUser(int userId, String login) =>
    BlackListItemInfo.fromJson(_appConfig, {'userId': userId, 'login': login});

ProfileInfo profileInfo(
  int userId,
  String login, {
  FriendshipStatus friendshipStatus = FriendshipStatus.notFriends,
}) => ProfileInfo(
  userId: userId,
  login: login,
  pictureUrl: null,
  role: Role.regular,
  lastVisitDate: DateTime(2026, 1, 1),
  banStatus: BanStatus.notBanned,
  friendshipStatus: friendshipStatus,
  authType: AuthType.native,
);

/// Records the calls it gets in [log]; the fields play the server's data.
class FakeApiRepository extends Fake implements ApiRepository {
  List<FriendInfo> friends = [];
  List<BlackListItemInfo> banlist = [];
  Map<int, ProfileInfo> profiles = {};

  /// When set, user actions wait for it to complete.
  Completer<void>? actionsGate;

  /// When set, every user action throws it.
  Object? actionError;

  /// When set, every list fetch throws it.
  Object? listError;

  final log = <String>[];

  @override
  Future<List<FriendInfo>> getFriendsList(bool forceRefresh) async {
    log.add('getFriendsList(forceRefresh: $forceRefresh)');
    _failListIfSet();
    return List.of(friends);
  }

  @override
  Future<List<BlackListItemInfo>> getBanlist(bool forceRefresh) async {
    log.add('getBanlist(forceRefresh: $forceRefresh)');
    _failListIfSet();
    return List.of(banlist);
  }

  @override
  Future<List<HistoryInfo>> getHistoryList(
    bool forceRefresh,
    BaseProfileInfo target,
  ) async {
    _failListIfSet();
    return [];
  }

  void _failListIfSet() {
    final error = listError;
    if (error != null) throw error;
  }

  @override
  Future<ProfileInfo> getProfileInfo(
    BaseProfileInfo target, [
    bool forceRefresh = false,
  ]) async => profiles[target.userId]!;

  @override
  Future sendNewFriendshipRequest(BaseProfileInfo target) async {
    await _act('sendNewFriendshipRequest(${target.userId})');
    profiles[target.userId] = profileInfo(
      target.userId,
      target.login,
      friendshipStatus: FriendshipStatus.inputRequest,
    );
  }

  @override
  Future deleteFriend(BaseProfileInfo friend) async {
    await _act('deleteFriend(${friend.userId})');
    friends.removeWhere((f) => f.userId == friend.userId);
  }

  @override
  Future sendFriendRequestAcceptance(
    BaseProfileInfo friend,
    bool isAccepted,
  ) async {
    await _act('sendFriendRequestAcceptance(${friend.userId}, $isAccepted)');
    friends = [
      for (final f in friends)
        if (f.userId != friend.userId)
          f
        else if (isAccepted)
          f.copy(accepted: true),
    ];
  }

  @override
  Future removeFromBanlist(BaseProfileInfo user) async {
    await _act('removeFromBanlist(${user.userId})');
    banlist.removeWhere((u) => u.userId == user.userId);
  }

  @override
  Future<void> removePicture() => _act('removePicture()');

  Future<void> _act(String call) async {
    log.add(call);
    await actionsGate?.future;
    final error = actionError;
    if (error != null) throw error;
  }
}

/// Returns [account] or throws [error], counting the calls in [fetches].
class FakeAccountManager extends Fake implements AccountManager {
  RemoteAccount? account;
  Object? error;
  int fetches = 0;

  FakeAccountManager(this.account);

  @override
  Future<RemoteAccount?> getLastSignedInAccount() async {
    fetches++;
    final error = this.error;
    if (error != null) throw error;
    return account;
  }
}

RemoteAccount remoteAccount(int userId, String name) => RemoteAccount(
  credential: Credential(userId: userId, accessToken: 'token'),
  name: name,
  canReceiveMessages: false,
  role: Role.regular,
  authType: AuthType.native,
  pictureUri: null,
);

/// Puts [screen] into an app that provides [repository] and,
/// when given, [accountManager].
Widget hostScreen(
  Widget screen, {
  required ApiRepository repository,
  AccountManager? accountManager,
}) => MultiRepositoryProvider(
  providers: [
    RepositoryProvider<ApiRepository>.value(value: repository),
    if (accountManager != null)
      RepositoryProvider<AccountManager>.value(value: accountManager),
  ],
  child: withTranslations(MaterialApp(home: Scaffold(body: screen))),
);
