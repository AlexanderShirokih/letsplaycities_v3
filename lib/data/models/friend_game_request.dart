import 'package:lets_play_cities/remote/auth.dart';

/// Describes types of friend game mode requests
enum FriendGameRequestType {
  /// Used to create new request
  invite,

  /// Used to accept and connect to previously created request
  join,
}

/// Struct that describes friend game request
class FriendGameRequest {
  /// Request envelope target
  final BaseProfileInfo target;

  /// Type of the request: new request or request result
  final FriendGameRequestType mode;

  const FriendGameRequest({required this.target, required this.mode});
}
