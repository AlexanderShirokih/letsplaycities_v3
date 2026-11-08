import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/remote/api_repository.dart';
import 'package:lets_play_cities/remote/auth/token_store.dart';
import 'package:lets_play_cities/remote/client/api_interceptor.dart';
import 'package:lets_play_cities/remote/client/social_api.dart';
import 'package:lets_play_cities/remote/model/lps_user.dart';
import 'package:lets_play_cities/remote/model/social.dart';

import 'fake_server.dart';

Map<String, Object?> _user(int id, [String name = 'user']) => {
  'id': id,
  'name': name,
  'avatarHash': 'abc',
  'provider': 'native',
  'lastSeenAt': 1700000000000,
};

Map<String, Object?> _entry(int id, [String status = 'friends']) => {
  'user': _user(id, 'friend$id'),
  'status': status,
};

Map<String, Object?> _game(int id) => {
  'id': id,
  'opponent': _user(2),
  'isFriend': false,
  'startedAt': 1700000000000,
  'durationSec': 60,
  'words': 10,
};

void main() {
  late FakeServer server;
  late ApiRepositoryCacheHolder cache;
  late ApiRepository repository;

  setUp(() {
    server = FakeServer();
    cache = ApiRepositoryCacheHolder();
    final dio = Dio(BaseOptions(baseUrl: 'https://lps.test/v1'))
      ..httpClientAdapter = server
      ..interceptors.add(
        ApiInterceptor(MemoryTokenStore('t'), onUnauthorized: (_) async {}),
      );
    repository = ApiRepository(
      SocialApi(dio),
      cache,
      AppConfig.forHost('lps.test'),
      dio,
    );
  });

  void serveUser(int id, String friendship) => server.on(
    'GET',
    '/v1/users/$id',
    200,
    {..._user(id), 'friendship': friendship, 'blocked': 'none'},
  );

  test('friends are requested once until a refresh', () async {
    server.on('GET', '/v1/friends', 200, [_entry(1)]);

    await repository.friends(false);
    await repository.friends(false);
    await repository.friends(true);

    expect(server.calls, ['GET /v1/friends', 'GET /v1/friends']);
  });

  test('deleteFriend removes the friend from the cached friends', () async {
    server
      ..on('GET', '/v1/friends', 200, [_entry(1), _entry(2)])
      ..on('DELETE', '/v1/friends/2', 204);
    await repository.friends(false);

    await repository.deleteFriend(2);
    final friends = await repository.friends(false);

    expect(friends.map((f) => f.user.id), [1]);
    expect(server.calls.where((c) => c == 'GET /v1/friends'), hasLength(1));
  });

  test('putFriend makes the next friends request refetch', () async {
    server
      ..on('GET', '/v1/friends', 200, [_entry(1)])
      ..on('PUT', '/v1/friends/3', 204);
    await repository.friends(false);

    await repository.putFriend(3);
    await repository.friends(false);

    expect(server.calls.where((c) => c == 'GET /v1/friends'), hasLength(2));
  });

  test('block clears friends cache', () async {
    server
      ..on('GET', '/v1/friends', 200, [_entry(1)])
      ..on('GET', '/v1/blocks', 200, [_user(9)])
      ..on('PUT', '/v1/blocks/1', 204);
    await repository.friends(false);
    await repository.blocks(false);

    await repository.putBlock(1);

    expect(cache.cachedFriends, isNull);
    expect(cache.cachedBlocks, isNull);
  });

  test('deleteBlock removes the user from the cached blocks', () async {
    server
      ..on('GET', '/v1/blocks', 200, [_user(1), _user(2)])
      ..on('DELETE', '/v1/blocks/1', 204);
    await repository.blocks(false);

    await repository.deleteBlock(1);
    final blocks = await repository.blocks(false);

    expect(blocks.map((b) => b.id), [2]);
  });

  test(
    'friend and block changes drop the cached profile of that user',
    () async {
      serveUser(3, 'none');
      server
        ..on('PUT', '/v1/friends/3', 204)
        ..on('DELETE', '/v1/friends/3', 204)
        ..on('PUT', '/v1/blocks/3', 204)
        ..on('DELETE', '/v1/blocks/3', 204);

      await repository.user(3);
      await repository.putFriend(3);
      await repository.user(3);
      await repository.deleteFriend(3);
      await repository.user(3);
      await repository.putBlock(3);
      await repository.user(3);
      await repository.deleteBlock(3);
      await repository.user(3);

      expect(server.calls.where((c) => c == 'GET /v1/users/3'), hasLength(5));
    },
  );

  test('a profile is cached until a refresh', () async {
    serveUser(4, 'friends');

    await repository.user(4);
    final cached = await repository.user(4);
    final fresh = await repository.user(4, true);

    expect(cached.friendship, Friendship.friends);
    expect(fresh.friendship, Friendship.friends);
    expect(server.calls.where((c) => c == 'GET /v1/users/4'), hasLength(2));
  });

  group('history', () {
    test('pages follow next and only the first page is cached', () async {
      server.on('GET', '/v1/history', 200, {
        'games': [_game(9)],
        'next': 9,
      });

      final first = await repository.history();
      await repository.history();
      final more = await repository.history(before: first.next);

      expect(server.requests, hasLength(2));
      expect(server.requests.first.queryParameters, isEmpty);
      expect(server.requests.last.queryParameters, {'before': 9});
      expect(more.games.single.id, 9);
    });

    test('the history with a user is cached apart', () async {
      server.on('GET', '/v1/history', 200, {'games': [], 'next': null});

      await repository.history();
      await repository.history(withUser: 2);
      await repository.history(withUser: 2);
      await repository.history(withUser: 2, forceRefresh: true);

      expect(server.requests.map((r) => r.queryParameters), [
        isEmpty,
        {'with': 2},
        {'with': 2},
      ]);
    });
  });

  test('putAvatar sends a 256x256 PNG', () async {
    server.on('PUT', '/v1/me/avatar', 200, _user(1));
    final source = img.encodeJpg(img.Image(width: 640, height: 480));

    await repository.putAvatar(Uint8List.fromList(source));

    final sent = server.bodyOf('PUT', '/v1/me/avatar') as Uint8List;
    final png = img.decodePng(sent)!;
    expect((png.width, png.height), (256, 256));
  });

  test('avatarUrl follows the picture server', () {
    final user = LpsUser.fromJson({..._user(7), 'avatarHash': 'h 1'});

    expect(
      repository.avatarUrl(user),
      'https://lps.test:443/v1/avatars/7?v=h+1',
    );
  });

  test('clear() drops every cached list, profile and history', () async {
    server
      ..on('GET', '/v1/friends', 200, [_entry(1)])
      ..on('GET', '/v1/blocks', 200, [_user(2)])
      ..on('GET', '/v1/history', 200, {'games': [], 'next': null});
    serveUser(3, 'none');
    await repository.friends(false);
    await repository.blocks(false);
    await repository.user(3);
    await repository.history();

    cache.clear();

    expect(cache.cachedFriends, isNull);
    expect(cache.cachedBlocks, isNull);
    expect(cache.cachedProfiles.get((_) => true), isNull);
    expect(cache.cachedHistories.get((_) => true), isNull);
  });
}
