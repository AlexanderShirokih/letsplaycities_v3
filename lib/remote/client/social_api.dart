import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:lets_play_cities/remote/client/api_exception.dart';
import 'package:lets_play_cities/remote/model/lps_user.dart';
import 'package:lets_play_cities/remote/model/social.dart';

/// Users, friends, blocks, history and the avatar on the REST API:
/// `/v1/users`, `/v1/friends`, `/v1/blocks`, `/v1/history` and
/// `/v1/me/avatar`.
///
/// An error answer of the server is thrown as [ApiException]; a request that
/// gets no answer throws [DioException].
class SocialApi {
  final Dio _dio;

  SocialApi(this._dio);

  /// The user [id] with the friendship and the block between the users
  Future<UserProfile> user(int id) async {
    final response = await _call(() => _dio.get('/users/$id'));

    return UserProfile.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<FriendEntry>> friends() async {
    final response = await _call(() => _dio.get('/friends'));

    return [
      for (final entry in response.data as List<dynamic>)
        FriendEntry.fromJson(entry as Map<String, dynamic>),
    ];
  }

  /// Sends a friend request to [id] or accepts the request of [id]
  Future<void> putFriend(int id) => _call(() => _dio.put<void>('/friends/$id'));

  /// Declines or cancels the request, or removes the friend [id]
  Future<void> deleteFriend(int id) =>
      _call(() => _dio.delete<void>('/friends/$id'));

  Future<List<LpsUser>> blocks() async {
    final response = await _call(() => _dio.get('/blocks'));

    return [
      for (final user in response.data as List<dynamic>)
        LpsUser.fromJson(user as Map<String, dynamic>),
    ];
  }

  /// Blocks [id]; the server ends their friendship
  Future<void> putBlock(int id) => _call(() => _dio.put<void>('/blocks/$id'));

  Future<void> deleteBlock(int id) =>
      _call(() => _dio.delete<void>('/blocks/$id'));

  /// A page of the history of the signed-in user: only the games with
  /// [withUser] if it is set, only the games before the cursor [before] if
  /// it is set
  Future<HistoryPage> history({int? withUser, int? before}) async {
    final response = await _call(
      () => _dio.get(
        '/history',
        queryParameters: {'with': ?withUser, 'before': ?before},
      ),
    );

    return HistoryPage.fromJson(response.data as Map<String, dynamic>);
  }

  /// Makes [png] the avatar of the signed-in user and returns the user
  Future<LpsUser> putAvatar(Uint8List png) async {
    final response = await _call(
      () => _dio.put(
        '/me/avatar',
        data: png,
        options: Options(contentType: 'image/png'),
      ),
    );

    return LpsUser.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteAvatar() => _call(() => _dio.delete<void>('/me/avatar'));

  Future<Response<T>> _call<T>(Future<Response<T>> Function() request) async {
    try {
      return await request();
    } on DioException catch (e, s) {
      final error = e.error;
      if (error is ApiException) Error.throwWithStackTrace(error, s);
      rethrow;
    }
  }
}
