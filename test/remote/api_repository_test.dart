import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/remote/auth.dart';

import 'fake_lps_api_client.dart';

void main() {
  late FakeLpsApiClient client;
  late ApiRepositoryCacheHolder cache;
  late ApiRepository repository;

  setUp(() {
    client = FakeLpsApiClient();
    cache = ApiRepositoryCacheHolder();
    repository = ApiRepository(client, cache, Dio());
  });

  test('deleteFriend from a profile page removes the friend from the cached '
      'friends list', () async {
    client.friends = [friend(1), friend(2)];
    await repository.getFriendsList(false);
    final friendProfile = await repository.getProfileInfo(profile(2));

    await repository.deleteFriend(friendProfile);
    final friends = await repository.getFriendsList(false);

    expect(friends.map((f) => f.userId), [1]);
    expect(client.friendsListCalls, 1);
  });

  test('deleteFriend drops the cached profile of the removed friend', () async {
    client.onGetProfileInfo = (id) =>
        profile(id, friendshipStatus: FriendshipStatus.friends);
    await repository.getProfileInfo(profile(2));

    await repository.deleteFriend(profile(2));
    client.onGetProfileInfo = (id) => profile(id);
    final refreshed = await repository.getProfileInfo(profile(2));

    expect(refreshed.friendshipStatus, FriendshipStatus.notFriends);
    expect(client.profileInfoCalls, [2, 2]);
  });

  test('removeFromBanlist removes the user from the cached ban list', () async {
    client.banList = [banned(1), banned(2)];
    await repository.getBanlist(false);

    await repository.removeFromBanlist(profile(1));
    final banList = await repository.getBanlist(false);

    expect(banList.map((b) => b.userId), [2]);
  });

  test('addToBanlist makes the next ban list request refetch', () async {
    client.banList = [banned(1)];
    await repository.getBanlist(false);

    client.banList = [banned(1), banned(2)];
    await repository.addToBanlist(profile(2));
    final banList = await repository.getBanlist(false);

    expect(banList.map((b) => b.userId), [1, 2]);
    expect(client.banListCalls, 2);
  });

  test('ban changes drop the cached profile of that user', () async {
    await repository.getProfileInfo(profile(3));

    await repository.addToBanlist(profile(3));
    await repository.getProfileInfo(profile(3));
    await repository.removeFromBanlist(profile(3));
    await repository.getProfileInfo(profile(3));

    expect(client.profileInfoCalls, [3, 3, 3]);
  });

  test('friend requests drop the cached profile of the target', () async {
    await repository.getProfileInfo(profile(4));

    await repository.sendNewFriendshipRequest(friend(4));
    await repository.getProfileInfo(profile(4));
    await repository.sendFriendRequestAcceptance(profile(4), true);
    await repository.getProfileInfo(profile(4));

    expect(client.profileInfoCalls, [4, 4, 4]);
  });

  test('clear() drops every cached list, profile and history', () async {
    client.friends = [friend(1)];
    client.banList = [banned(2)];
    await repository.getFriendsList(false);
    await repository.getBanlist(false);
    await repository.getProfileInfo(profile(3));
    await repository.getHistoryList(false, profile(3));

    cache.clear();

    expect(cache.cachedFriendsList, isNull);
    expect(cache.cachedBanList, isNull);
    expect(cache.cachedProfilesInfo.get((_) => true), isNull);
    expect(cache.cachedHistoriesInfo.get((_) => true), isNull);
  });
}
