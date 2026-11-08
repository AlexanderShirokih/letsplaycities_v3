import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/base/achievements/achievements.dart';
import 'package:lets_play_cities/base/achievements/achievements_service.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/model/lps_user.dart';
import 'package:lets_play_cities/remote/model/social.dart';

import '../../i18n/translations_harness.dart';

LpsUser lpsUser(
  int id,
  String name, {
  DateTime? lastSeenAt,
  String? avatarHash,
}) => LpsUser(
  id: id,
  name: name,
  avatarHash: avatarHash,
  provider: 'native',
  lastSeenAt: lastSeenAt ?? DateTime(2026, 1, 1),
);

FriendEntry friendEntry(
  int id,
  String name,
  FriendStatus status, {
  DateTime? lastSeenAt,
}) => FriendEntry(lpsUser(id, name, lastSeenAt: lastSeenAt), status);

UserProfile userProfile(
  int id,
  String name, {
  Friendship friendship = Friendship.none,
  Blocked blocked = Blocked.none,
}) => UserProfile(
  user: lpsUser(id, name),
  friendship: friendship,
  blocked: blocked,
);

/// Keeps the achievements it was asked to unlock.
class FakeAchievementsService extends Fake implements AchievementsService {
  final unlocked = <Achievement>[];

  @override
  Future<void> unlockAchievement(
    Achievement achievement, [
    int incrementCount = 1,
  ]) async => unlocked.add(achievement);
}

/// Registers a [FakeAchievementsService] in GetIt until the test ends.
FakeAchievementsService registerFakeAchievements() {
  final achievements = FakeAchievementsService();
  GetIt.instance.registerSingleton<AchievementsService>(achievements);
  addTearDown(GetIt.instance.reset);
  return achievements;
}

/// Records the calls it gets in [log]; the fields play the server's data.
class FakeApiRepository extends Fake implements ApiRepository {
  List<FriendEntry> friendEntries = [];
  List<LpsUser> blocked = [];
  Map<int, UserProfile> profiles = {};
  List<HistoryGame> games = [];

  /// Games on a page of the history
  int pageSize = 50;

  /// When set, user actions wait for it to complete.
  Completer<void>? actionsGate;

  /// When set, every user action throws it.
  Object? actionError;

  /// When set, every list fetch throws it.
  Object? listError;

  final log = <String>[];

  /// The history requests, kept apart: a profile shows the history too
  final historyCalls = <String>[];

  /// `forceRefresh` of each request for a user
  final userCalls = <bool>[];

  @override
  String? avatarUrl(LpsUser user) => null;

  @override
  Future<List<FriendEntry>> friends(bool forceRefresh) async {
    log.add('friends(forceRefresh: $forceRefresh)');
    _failListIfSet();
    return List.of(friendEntries);
  }

  @override
  Future<List<LpsUser>> blocks(bool forceRefresh) async {
    log.add('blocks(forceRefresh: $forceRefresh)');
    _failListIfSet();
    return List.of(blocked);
  }

  @override
  Future<HistoryPage> history({
    int? withUser,
    int? before,
    bool forceRefresh = false,
  }) async {
    historyCalls.add('history(withUser: $withUser, before: $before)');
    _failListIfSet();
    final rest = games.where((g) => before == null || g.id < before).toList();
    final page = rest.take(pageSize).toList();

    return HistoryPage(page, rest.length > page.length ? page.last.id : null);
  }

  void _failListIfSet() {
    final error = listError;
    if (error != null) throw error;
  }

  @override
  Future<UserProfile> user(int id, [bool forceRefresh = false]) async {
    userCalls.add(forceRefresh);
    return profiles[id]!;
  }

  @override
  Future<void> putFriend(int userId) async {
    await _act('putFriend($userId)');
    final profile = profiles[userId];
    if (profile != null) {
      profiles[userId] = userProfile(
        userId,
        profile.user.name,
        friendship: profile.friendship == Friendship.incoming
            ? Friendship.friends
            : Friendship.outgoing,
      );
    }
    friendEntries = [
      for (final e in friendEntries)
        if (e.user.id == userId && e.status == FriendStatus.incoming)
          FriendEntry(e.user, FriendStatus.friends)
        else
          e,
    ];
  }

  @override
  Future<void> deleteFriend(int userId) async {
    await _act('deleteFriend($userId)');
    friendEntries.removeWhere((f) => f.user.id == userId);
  }

  @override
  Future<void> putBlock(int userId) => _act('putBlock($userId)');

  @override
  Future<void> deleteBlock(int userId) async {
    await _act('deleteBlock($userId)');
    blocked.removeWhere((u) => u.id == userId);
  }

  @override
  Future<void> deleteAvatar() => _act('deleteAvatar()');

  @override
  Future<LpsUser> putAvatar(Uint8List image) async {
    await _act('putAvatar(${image.length})');
    return lpsUser(1, 'Bob', avatarHash: 'new');
  }

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

  final changes = StreamController<void>.broadcast();
  int invalidations = 0;

  @override
  Stream<void> get accountChanges => changes.stream;

  @override
  void invalidate() {
    invalidations++;
    changes.add(null);
  }

  int signOuts = 0;

  @override
  Future<void> signOut() async {
    signOuts++;
    account = null;
    changes.add(null);
  }
}

RemoteAccount remoteAccount(int userId, String name) => RemoteAccount(
  LpsUser(
    id: userId,
    name: name,
    provider: 'native',
    lastSeenAt: DateTime(2026, 1, 1),
  ),
);

/// Puts [screen] into an app that provides [repository].
Widget hostScreen(Widget screen, {required ApiRepository repository}) =>
    RepositoryProvider<ApiRepository>.value(
      value: repository,
      child: withTranslations(MaterialApp(home: Scaffold(body: screen))),
    );
