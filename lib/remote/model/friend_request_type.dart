/// Describes friendship request type
enum FriendRequestType {
  /// Sends new friend request
  send('SEND'),

  /// Accepts input friend request
  accept('ACCEPT'),

  /// Denies input friend request
  deny('DENY');

  const FriendRequestType(this.wireName);

  /// Last segment of the friend request path
  final String wireName;
}
