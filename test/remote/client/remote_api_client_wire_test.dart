import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/auth/token_store.dart';
import 'package:lets_play_cities/remote/model/friend_request_type.dart';

/// Records each request and answers it with an empty 200 response.
class _RecordingServer implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString('', 200);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('sendFriendRequest', () {
    // The server reads the request type from the last path segment in upper
    // case.
    const paths = {
      FriendRequestType.send: '/friend/request/9/SEND',
      FriendRequestType.accept: '/friend/request/9/ACCEPT',
      FriendRequestType.deny: '/friend/request/9/DENY',
    };

    late _RecordingServer server;
    late RemoteLpsApiClient client;

    setUp(() {
      server = _RecordingServer();
      client = RemoteLpsApiClient(
        AppConfig.forHost('api.test'),
        Dio(BaseOptions(baseUrl: 'https://api.test'))
          ..httpClientAdapter = server,
        MemoryTokenStore('token'),
        1,
      );
    });

    test('has a pinned path for every request type', () {
      expect(paths.keys.toSet(), FriendRequestType.values.toSet());
    });

    for (final MapEntry(key: type, value: path) in paths.entries) {
      test('$type is a PUT to $path', () async {
        await client.sendFriendRequest(9, type);

        expect(server.requests.single.method, 'PUT');
        expect(server.requests.single.path, path);
      });
    }
  });

  group('RemoteSignUpResponse', () {
    // The sign-up response stores the role as 'state' with the server's
    // names; Role.regular is 'ready' there.
    const states = {
      Role.banned: 'banned',
      Role.regular: 'ready',
      Role.admin: 'admin',
    };

    for (final MapEntry(key: role, value: state) in states.entries) {
      test('writes and reads $role as state "$state"', () {
        final response = RemoteSignUpResponse(
          userId: 42,
          login: 'Alice',
          accessToken: 'acc',
          pictureHash: 'pic',
          role: role,
          authType: AuthType.vkontakte,
        );

        final map = response.toMap();
        final read = RemoteSignUpResponse.fromMap(map);

        expect(map, {
          'userId': 42,
          'name': 'Alice',
          'accHash': 'acc',
          'picHash': 'pic',
          'state': state,
          'authType': 'Vkontakte',
        });
        expect(read.role, role);
        expect(read.authType, AuthType.vkontakte);
      });
    }

    test('reading an unknown state throws', () {
      expect(
        () => RemoteSignUpResponse.fromMap({
          'userId': 42,
          'name': 'Alice',
          'accHash': 'acc',
          'picHash': 'pic',
          'state': 'regular',
          'authType': 'Native',
        }),
        throwsA(isA<String>()),
      );
    });
  });
}
