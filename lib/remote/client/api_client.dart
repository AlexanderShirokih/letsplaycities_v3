import 'package:lets_play_cities/remote/client/remote_api_client.dart';
import 'package:lets_play_cities/remote/model/blacklist_item_info.dart';
import 'package:lets_play_cities/remote/model/friend_info.dart';
import 'package:lets_play_cities/remote/model/friend_request_type.dart';
import 'package:lets_play_cities/remote/model/history_info.dart';
import 'package:lets_play_cities/remote/model/profile_info.dart';

/// LPS remote service client
abstract class LpsApiClient {
  const LpsApiClient();

  /// Sends sign up request and returns [RemoteSignUpResponse] containing user data
  /// or throws [AuthorizationException] if cannot sign up on server by any reason.
  Future<RemoteSignUpResponse> signUp(RemoteSignUpData data);

  /// Queries friends list from server. Throws an exception if cannot fetch data.
  Future<List<FriendInfo>> getFriendsList();

  /// Queries ban list from server. Throws an exception if cannot fetch data.
  Future<List<BlackListItemInfo>> getBanList();

  /// Queries battle history list from server. Throws an exception if cannot
  /// fetch data. If [targetId] passes common history of signed in user and
  /// target user will shown.
  Future<List<HistoryInfo>> getHistoryList([int targetId]);

  /// Deletes a user with id [friendId] from user's friend list
  Future deleteFriend(int friendId);

  /// Sends a friendship request
  Future sendFriendRequest(int friendId, FriendRequestType requestType);

  /// Removes a user with [userId] from players ban list
  Future removeFromBanlist(int userId);

  /// Adds a user with [userId] to players ban list
  Future addToBanlist(int userId);

  /// Sends negative result to the game request sent by [requesterId]
  Future<void> declineGameRequest(int requesterId);

  /// Fetches information about user profile
  /// If [targetId] is passed profile info about that user will be fetched.
  /// If [targetId] is null info about current user will be fetched
  Future<ProfileInfo> getProfileInfo(int targetId);

  /// Updates picture for currently logged account
  Future updatePicture(List<int> thumbnail, String imageType);

  /// Removes user picture from currently logged account
  Future removePicture();
}
