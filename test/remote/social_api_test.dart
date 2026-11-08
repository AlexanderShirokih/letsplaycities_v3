import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/remote/auth/token_store.dart';
import 'package:lets_play_cities/remote/client/api_exception.dart';
import 'package:lets_play_cities/remote/client/api_interceptor.dart';
import 'package:lets_play_cities/remote/client/social_api.dart';
import 'package:lets_play_cities/remote/model/social.dart';

import 'fake_server.dart';

Map<String, Object?> _user(int id, [String name = 'Alice']) => {
  'id': id,
  'name': name,
  'avatarHash': null,
  'provider': 'native',
  'lastSeenAt': 1700000000000,
};

void main() {
  late FakeServer server;
  late SocialApi api;

  setUp(() {
    server = FakeServer();
    final dio = Dio(BaseOptions(baseUrl: 'https://lps.test/v1'))
      ..httpClientAdapter = server
      ..interceptors.add(
        ApiInterceptor(MemoryTokenStore('t'), onUnauthorized: (_) async {}),
      );
    api = SocialApi(dio);
  });

  test('user reads the user with friendship and blocked', () async {
    server.on('GET', '/v1/users/2', 200, {
      ..._user(2),
      'friendship': 'incoming',
      'blocked': 'byMe',
    });

    final profile = await api.user(2);

    expect(server.calls, ['GET /v1/users/2']);
    expect(profile.user.name, 'Alice');
    expect(profile.friendship, Friendship.incoming);
    expect(profile.blocked, Blocked.byMe);
  });

  test('friends reads the entries with their status', () async {
    server.on('GET', '/v1/friends', 200, [
      {'user': _user(2), 'status': 'friends'},
      {'user': _user(3, 'Bob'), 'status': 'incoming'},
      {'user': _user(4, 'Carol'), 'status': 'outgoing'},
    ]);

    final friends = await api.friends();

    expect(friends.map((e) => e.user.id), [2, 3, 4]);
    expect(friends.map((e) => e.status), [
      FriendStatus.friends,
      FriendStatus.incoming,
      FriendStatus.outgoing,
    ]);
  });

  test('putFriend is a PUT to /friends/{id}', () async {
    server.on('PUT', '/v1/friends/5', 204);

    await api.putFriend(5);

    expect(server.calls, ['PUT /v1/friends/5']);
  });

  test('deleteFriend is a DELETE to /friends/{id}', () async {
    server.on('DELETE', '/v1/friends/5', 204);

    await api.deleteFriend(5);

    expect(server.calls, ['DELETE /v1/friends/5']);
  });

  test('blocks reads the blocked users', () async {
    server.on('GET', '/v1/blocks', 200, [_user(2), _user(3, 'Bob')]);

    final blocks = await api.blocks();

    expect(blocks.map((u) => u.name), ['Alice', 'Bob']);
  });

  test('putBlock and deleteBlock use /blocks/{id}', () async {
    server
      ..on('PUT', '/v1/blocks/5', 204)
      ..on('DELETE', '/v1/blocks/5', 204);

    await api.putBlock(5);
    await api.deleteBlock(5);

    expect(server.calls, ['PUT /v1/blocks/5', 'DELETE /v1/blocks/5']);
  });

  group('history', () {
    final body = {
      'games': [
        {
          'id': 9,
          'opponent': _user(2),
          'isFriend': true,
          'startedAt': 1700000000000,
          'durationSec': 75,
          'words': 21,
        },
      ],
      'next': 9,
    };

    test('reads the games and the cursor', () async {
      server.on('GET', '/v1/history', 200, body);

      final page = await api.history();

      expect(server.requests.single.queryParameters, isEmpty);
      expect(page.next, 9);
      final game = page.games.single;
      expect(game.id, 9);
      expect(game.opponent.id, 2);
      expect(game.isFriend, isTrue);
      expect(game.durationSec, 75);
      expect(game.words, 21);
      expect(
        game.startedAt,
        DateTime.fromMillisecondsSinceEpoch(1700000000000),
      );
    });

    test('sends with and before as query parameters', () async {
      server.on('GET', '/v1/history', 200, {'games': [], 'next': null});

      final page = await api.history(withUser: 2, before: 9);

      expect(server.requests.single.queryParameters, {'with': 2, 'before': 9});
      expect(page.games, isEmpty);
      expect(page.next, isNull);
    });
  });

  test('putAvatar sends the PNG bytes and returns the user', () async {
    server.on('PUT', '/v1/me/avatar', 200, {..._user(1), 'avatarHash': 'h1'});
    final png = Uint8List.fromList([1, 2, 3]);

    final user = await api.putAvatar(png);

    expect(server.bodyOf('PUT', '/v1/me/avatar'), png);
    expect(server.requests.single.headers['content-type'], 'image/png');
    expect(user.avatarHash, 'h1');
  });

  test('deleteAvatar is a DELETE to /me/avatar', () async {
    server.on('DELETE', '/v1/me/avatar', 204);

    await api.deleteAvatar();

    expect(server.calls, ['DELETE /v1/me/avatar']);
  });

  test('an error answer is thrown as ApiException', () async {
    server.fail('PUT', '/v1/me/avatar', 400, 'bad_image');

    await expectLater(
      api.putAvatar(Uint8List(1)),
      throwsA(
        isA<ApiException>()
            .having((e) => e.code, 'code', 'bad_image')
            .having((e) => e.message, 'message', 'Server says bad_image'),
      ),
    );
  });

  test('a 401 is thrown as UnauthorizedException', () async {
    server.fail('GET', '/v1/friends', 401, 'unauthorized');

    await expectLater(api.friends(), throwsA(isA<UnauthorizedException>()));
  });
}
