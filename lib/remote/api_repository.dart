import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/model/friend_info.dart';
import 'package:lets_play_cities/remote/model/friend_request_type.dart';

/// Repository class wrapping [LpsApiClient]
class ApiRepository {
  final LpsApiClient _client;
  List<FriendInfo> _cachedFriendsList;

  ApiRepository(this._client);

  /// Gets user friends list.
  /// Network request will used only first time or when [forceLoading] is `true`
  /// in all the other cases cached instance of friends list will be used.
  Future<List<FriendInfo>> getFriendsList(bool forceLoading) async {
    if (_cachedFriendsList == null || forceLoading) {
      _cachedFriendsList = await _client.getFriendsList();
    }
    return _cachedFriendsList;
  }

  /// Deletes friend from friend list.
  Future deleteFriend(int friendId) => _client.deleteFriend(friendId);

  /// Accepts or denies input friendship request from user [friendId]
  Future sendFriendRequestAcceptance(int friendId, bool isAccepted) =>
      _client.sendFriendRequest(
        friendId,
        isAccepted ? FriendRequestType.ACCEPT : FriendRequestType.DENY,
      );

  /// Sends new friendship request
  Future sendNewFriendshipRequest(int targetId) =>
      _client.sendFriendRequest(targetId, FriendRequestType.SEND);
}
